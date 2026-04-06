import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { insertAnalysis, getWeights } from '../db';
import { analyze } from '../score';
import { estimatePartsRiskWithProviders, getPartsCatalog } from '../services/parts';
import { AnalysisInputSchema } from '../contracts';

const PartsInputSchema = z.object({
  brand: z.string().min(2),
  model: z.string().min(1),
  year: z.coerce.number().int().min(1950).max(new Date().getFullYear() + 1),
  region: z.string().min(2).max(120).optional(),
  odometerKm: z.coerce.number().nonnegative().optional(),
  usageProfile: z.enum(['urban', 'mixed', 'highway']).optional(),
  monthlyIncomeReference: z.coerce.number().positive().optional(),
});

const CombinedAnalysisSchema = z.object({
  analysis: AnalysisInputSchema,
  parts: PartsInputSchema,
  clientId: z.string().min(8).max(120).optional(),
  weights: z
    .object({
      car: z.number().nonnegative().default(0.7),
      parts: z.number().nonnegative().default(0.3),
    })
    .optional(),
});

export async function partsRoutes(app: FastifyInstance) {
  app.get('/v1/parts/catalog', async (request, reply) => {
    const parsed = PartsInputSchema.pick({
      brand: true,
      model: true,
      year: true,
      region: true,
      odometerKm: true,
      usageProfile: true,
    }).safeParse(request.query);

    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }

    const items = getPartsCatalog(parsed.data);

    return {
      input: {
        ...parsed.data,
        region: parsed.data.region ?? 'nacional',
        odometerKm: parsed.data.odometerKm ?? 60000,
        usageProfile: parsed.data.usageProfile ?? 'mixed',
      },
      items,
      count: items.length,
      source: 'local_seed_v1',
    };
  });

  app.post('/v1/parts/estimate', async (request, reply) => {
    const parsed = PartsInputSchema.safeParse(request.body);

    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }

    const result = await estimatePartsRiskWithProviders(parsed.data);
    return {
      result,
    };
  });

  app.post('/v1/analysis/estimate-with-parts', async (request, reply) => {
    const parsed = CombinedAnalysisSchema.safeParse(request.body);

    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }

    const serverWeights = await getWeights();
    const carResult = analyze(parsed.data.analysis, serverWeights);
    const partsResult = await estimatePartsRiskWithProviders(parsed.data.parts);
    const combinedWeights = parsed.data.weights ?? { car: 0.7, parts: 0.3 };
    const sum = combinedWeights.car + combinedWeights.parts;

    if (sum <= 0) {
      return reply.status(400).send({
        error: 'invalid_weights',
        message: 'The sum of car and parts weights must be greater than zero.',
      });
    }

    const normalizedCombined = {
      car: combinedWeights.car / sum,
      parts: combinedWeights.parts / sum,
    };

    const combinedScore = Math.round(
      carResult.finalScore * normalizedCombined.car + partsResult.partsScore * normalizedCombined.parts
    );

    let combinedLabel = 'nao_recomendado';
    if (combinedScore >= 80) combinedLabel = 'compra_saudavel';
    else if (combinedScore >= 60) combinedLabel = 'viavel_com_atencao';
    else if (combinedScore >= 40) combinedLabel = 'alto_custo_para_perfil';

    const analysisId = await insertAnalysis({
      clientId: parsed.data.clientId,
      input: parsed.data.analysis,
      result: carResult,
      parts: {
        partsScore: partsResult.partsScore,
        label: partsResult.label,
        annualPartsCost: partsResult.annualPartsCost,
        monthlyPartsCost: partsResult.monthlyPartsCost,
      },
      combined: {
        score: combinedScore,
        label: combinedLabel,
        weights: normalizedCombined,
      },
    });

    return {
      input: parsed.data,
      result: {
        car: carResult,
        parts: partsResult,
        combined: {
          score: combinedScore,
          label: combinedLabel,
          weights: normalizedCombined,
        },
      },
      meta: {
        analysisId,
      },
    };
  });
}
