import { FastifyInstance } from 'fastify';
import { z } from 'zod';
import { getAvailableOfferProviders, searchOffers } from '../services/offers';

const QuerySchema = z.object({
  region: z.string().min(1).max(120).default('Sao Paulo'),
  limit: z.coerce.number().int().min(1).max(30).default(12),
  brand: z.string().min(1).max(60).optional(),
  model: z.string().min(1).max(80).optional(),
  minPrice: z.coerce.number().nonnegative().optional(),
  maxPrice: z.coerce.number().nonnegative().optional(),
  maxKm: z.coerce.number().int().nonnegative().optional(),
  minYear: z.coerce.number().int().min(1950).max(new Date().getFullYear() + 1).optional(),
  providers: z
    .string()
    .optional()
    .transform((value) =>
      value
        ?.split(',')
        .map((item) => item.trim())
        .filter(Boolean) as Array<'mercadolivre' | 'local'> | undefined
    ),
});

export async function offersRoutes(app: FastifyInstance) {
  app.get('/v1/offers', async (request, reply) => {
    const parsed = QuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return reply.status(400).send({ error: 'invalid_query', details: parsed.error.flatten() });
    }

    const result = await searchOffers(parsed.data);

    return {
      items: result.items,
      count: result.items.length,
      region: parsed.data.region,
      filters: {
        brand: parsed.data.brand ?? null,
        model: parsed.data.model ?? null,
        minPrice: parsed.data.minPrice ?? null,
        maxPrice: parsed.data.maxPrice ?? null,
        maxKm: parsed.data.maxKm ?? null,
        minYear: parsed.data.minYear ?? null,
      },
      providersUsed: result.providersUsed,
      fallbackUsed: result.fallbackUsed,
      availableProviders: getAvailableOfferProviders(),
    };
  });
}
