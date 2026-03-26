import { describe, it, expect } from 'vitest';
import { analyze } from '../src/score';

describe('score analysis', () => {
  it('returns high score for cheap, efficient car', () => {
    const input = {
      vehicleLabel: 'Compacto',
      year: new Date().getFullYear() - 1,
      askingPrice: 20000,
      kmPerMonth: 400,
      kmPerLiter: 16,
      fuelPricePerLiter: 5,
      maintenanceMonthly: 50,
    };
    const res = analyze(input);
    expect(res.finalScore).toBeGreaterThanOrEqual(70);
  });

  it('returns low score for expensive, thirsty car', () => {
    const input = {
      vehicleLabel: 'SUV Grande',
      year: 2010,
      askingPrice: 120000,
      kmPerMonth: 1500,
      kmPerLiter: 6,
      fuelPricePerLiter: 6,
      maintenanceMonthly: 400,
    };
    const res = analyze(input);
    expect(res.finalScore).toBeLessThanOrEqual(50);
  });
});
