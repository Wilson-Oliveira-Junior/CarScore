import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import { app, buildServer } from '../src/server';

describe('API routes', () => {
  beforeAll(async () => {
    await buildServer();
  });

  afterAll(async () => {
    await app.close();
  });

  it('GET /health returns ok', async () => {
    const response = await app.inject({ method: 'GET', url: '/health' });
    expect(response.statusCode).toBe(200);
    expect(response.json()).toEqual({ status: 'ok', service: 'carscore-api' });
  });

  it('GET /v1/parts/catalog returns catalog payload', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/v1/parts/catalog?brand=Honda&model=Civic&year=2019',
    });
    expect(response.statusCode).toBe(200);
    const payload = response.json();
    expect(payload.items).toBeInstanceOf(Array);
    expect(payload.items.length).toBeGreaterThan(0);
    expect(payload.input.brand).toBe('Honda');
  });

  it('POST /v1/analysis/estimate-with-parts returns combined estimate', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/analysis/estimate-with-parts',
      payload: {
        analysis: {
          vehicleLabel: 'Honda Civic',
          year: 2020,
          askingPrice: 80000,
          kmPerMonth: 800,
          kmPerLiter: 12,
          fuelPricePerLiter: 5.5,
          maintenanceMonthly: 120,
        },
        parts: {
          brand: 'Honda',
          model: 'Civic',
          year: 2020,
          region: 'Sao Paulo',
          odometerKm: 50000,
          usageProfile: 'mixed',
          monthlyIncomeReference: 7000,
        },
      },
    });

    expect(response.statusCode).toBe(200);
    const payload = response.json();
    expect(payload.result).toHaveProperty('car');
    expect(payload.result).toHaveProperty('parts');
    expect(payload.result).toHaveProperty('combined');
    expect(payload.meta).toHaveProperty('analysisId');
  });

  it('POST /v1/analysis/estimate-with-parts rejects invalid payload', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/v1/analysis/estimate-with-parts',
      payload: { analysis: {}, parts: {} },
    });
    expect(response.statusCode).toBe(400);
    expect(response.json().error).toBe('invalid_payload');
  });
});