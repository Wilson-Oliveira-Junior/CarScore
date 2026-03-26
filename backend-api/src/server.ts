import Fastify from 'fastify';
import cors from '@fastify/cors';
import { z } from 'zod';
import { analyze } from './score';

const app = Fastify({ logger: true });

async function buildServer() {
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
    const analysis = analyze(data);
    return {
      input: data,
      result: analysis,
    };
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
