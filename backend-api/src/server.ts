import Fastify from 'fastify';
import cors from '@fastify/cors';
import { z } from 'zod';
import { analyze } from './score';
import { getAnalysisHistory, getWeights, initDb, insertAnalysis, updateWeights } from './db';

const app = Fastify({ logger: true });

async function buildServer() {
  await initDb();

  await app.register(cors, {
    origin: true,
  });

  app.get('/health', async () => {
    return { status: 'ok', service: 'carscore-api' };
  });

  app.post('/v1/analysis/estimate', async (request, reply) => {
    const bodySchema = z.object({
      vehicleLabel: z.string().min(3),
      year: z.number().int().min(1950).max(new Date().getFullYear() + 1),
      askingPrice: z.number().positive(),
      kmPerMonth: z.number().positive(),
      kmPerLiter: z.number().positive(),
      fuelPricePerLiter: z.number().positive(),
      maintenanceMonthly: z.number().nonnegative().default(0),
    });

    const parsed = bodySchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'invalid_payload',
        details: parsed.error.flatten(),
      });
    }

    const data = parsed.data;
    const weights = await getWeights();
    const result = analyze(data, weights);
    const analysisId = await insertAnalysis({ input: data, result });

    return {
      input: data,
      result,
      meta: {
        analysisId,
      },
    };
  });

  app.get('/v1/analysis/history', async (request) => {
    const querySchema = z.object({
      limit: z.coerce.number().int().min(1).max(100).optional(),
    });

    const parsed = querySchema.safeParse(request.query);
    const limit = parsed.success ? parsed.data.limit ?? 20 : 20;
    const history = await getAnalysisHistory(limit);

    return {
      items: history,
      count: history.length,
    };
  });

  app.get('/v1/config/weights', async () => {
    const weights = await getWeights();
    return { weights };
  });

  app.put('/v1/config/weights', async (request, reply) => {
    const bodySchema = z.object({
      price: z.number().nonnegative(),
      fuel: z.number().nonnegative(),
      maintenance: z.number().nonnegative(),
      adequacy: z.number().nonnegative(),
    });

    const parsed = bodySchema.safeParse(request.body);
    if (!parsed.success) {
      return reply.status(400).send({
        error: 'invalid_payload',
        details: parsed.error.flatten(),
      });
    }

    const sum =
      parsed.data.price +
      parsed.data.fuel +
      parsed.data.maintenance +
      parsed.data.adequacy;

    if (sum <= 0) {
      return reply.status(400).send({
        error: 'invalid_weights',
        message: 'The sum of all weights must be greater than zero.',
      });
    }

    const weights = await updateWeights(parsed.data);
    return { weights };
  });
}

buildServer()
  .then(async () => {
    await app.listen({ port: 3333, host: '0.0.0.0' });
  })
  .catch((error) => {
    app.log.error(error);
    process.exit(1);
  });
