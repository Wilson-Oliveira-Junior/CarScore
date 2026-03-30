/**
 * routes/vehicles.ts
 * Endpoints de consulta de veículos: FIPE + Inmetro/PBE.
 */
import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { getBrands, getModels, getYears, getPriceWithSource, parseFipeValue } from '../services/fipe';
import { lookupConsumption } from '../services/inmetro';

export async function vehicleRoutes(app: FastifyInstance) {
  // GET /v1/vehicles/brands
  app.get('/v1/vehicles/brands', async (_req, reply) => {
    try {
      const brands = await getBrands();
      return {
        items: brands.map((b) => ({ code: b.codigo, name: b.nome })),
        count: brands.length,
      };
    } catch (err) {
      app.log.error(err);
      return reply.status(502).send({ error: 'fipe_unavailable', message: 'FIPE API fora do ar. Tente novamente.' });
    }
  });

  // GET /v1/vehicles/models?brandCode=59
  app.get('/v1/vehicles/models', async (request, reply) => {
    const querySchema = z.object({ brandCode: z.string().min(1) });
    const parsed = querySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }
    try {
      const models = await getModels(parsed.data.brandCode);
      return {
        items: models.map((m) => ({ code: m.codigo, name: m.nome })),
        count: models.length,
      };
    } catch (err) {
      app.log.error(err);
      return reply.status(502).send({ error: 'fipe_unavailable', message: 'FIPE API fora do ar. Tente novamente.' });
    }
  });

  // GET /v1/vehicles/years?brandCode=59&modelCode=5940
  app.get('/v1/vehicles/years', async (request, reply) => {
    const querySchema = z.object({
      brandCode: z.string().min(1),
      modelCode: z.coerce.number().int().positive(),
    });
    const parsed = querySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }
    try {
      const years = await getYears(parsed.data.brandCode, parsed.data.modelCode);
      return {
        items: years.map((y) => ({ code: y.codigo, name: y.nome })),
        count: years.length,
      };
    } catch (err) {
      app.log.error(err);
      return reply.status(502).send({ error: 'fipe_unavailable', message: 'FIPE API fora do ar. Tente novamente.' });
    }
  });

  // GET /v1/vehicles/fipe-price?brandCode=59&modelCode=5940&yearCode=2018-1
  app.get('/v1/vehicles/fipe-price', async (request, reply) => {
    const querySchema = z.object({
      brandCode: z.string().min(1),
      modelCode: z.coerce.number().int().positive(),
      yearCode: z.string().min(1),
    });
    const parsed = querySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }
    try {
      const resolved = await getPriceWithSource(
        parsed.data.brandCode,
        parsed.data.modelCode,
        parsed.data.yearCode
      );
      const price = resolved.price;
      return {
        fipeCode: price.codigoFipe,
        brand: price.marca,
        model: price.modelo,
        yearModel: price.anoModelo,
        fuel: price.combustivel,
        referencePrice: parseFipeValue(price.valor),
        referencePriceFormatted: price.valor,
        referenceMonth: price.mesReferencia,
        source: resolved.source,
        sourceName: resolved.sourceName,
        isFallback: resolved.isFallback,
      };
    } catch (err) {
      app.log.error(err);
      return reply.status(502).send({ error: 'fipe_unavailable', message: 'FIPE API fora do ar. Tente novamente.' });
    }
  });

  // GET /v1/vehicles/consumption?brand=honda&model=civic&year=2020
  app.get('/v1/vehicles/consumption', async (request, reply) => {
    const querySchema = z.object({
      brand: z.string().min(2),
      model: z.string().min(2),
      year: z.coerce.number().int().min(1950).max(new Date().getFullYear() + 1),
    });
    const parsed = querySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_payload', details: parsed.error.flatten() });
    }
    const record = lookupConsumption(parsed.data.brand, parsed.data.model, parsed.data.year);
    if (!record) {
      return reply.status(404).send({
        error: 'not_found',
        message: 'Consumo não encontrado na base Inmetro para esse veículo/ano.',
      });
    }
    return {
      brand: record.brand,
      model: record.model,
      yearFrom: record.yearFrom,
      yearTo: record.yearTo,
      engine: record.engine,
      fuel: record.fuel,
      consumption: {
        urbanKmL: record.urbanKmL,
        roadKmL: record.roadKmL,
        averageKmL: parseFloat(((record.urbanKmL + record.roadKmL) / 2).toFixed(1)),
        ethanolUrbanKmL: record.ethanolUrbanKmL ?? null,
        ethanolRoadKmL: record.ethanolRoadKmL ?? null,
        ethanolAverageKmL: record.ethanolUrbanKmL && record.ethanolRoadKmL
          ? parseFloat(((record.ethanolUrbanKmL + record.ethanolRoadKmL) / 2).toFixed(1))
          : null,
      },
      source: 'inmetro_pbe_seed_v1',
    };
  });
}
