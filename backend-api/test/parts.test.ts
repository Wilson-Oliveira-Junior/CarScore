import { describe, expect, it } from 'vitest';
import { estimatePartsRisk, getPartsCatalog } from '../src/services/parts';

describe('parts analysis', () => {
  it('returns catalog with baseline parts', () => {
    const items = getPartsCatalog({
      brand: 'Honda',
      model: 'Civic',
      year: 2019,
    });

    expect(items.length).toBeGreaterThanOrEqual(7);
    expect(items[0].avgPrice).toBeGreaterThan(0);
  });

  it('returns lower score for premium brand and lower income', () => {
    const premium = estimatePartsRisk({
      brand: 'BMW',
      model: '320i',
      year: 2018,
      usageProfile: 'urban',
      monthlyIncomeReference: 3500,
      odometerKm: 110000,
    });

    const popular = estimatePartsRisk({
      brand: 'Fiat',
      model: 'Argo',
      year: 2019,
      usageProfile: 'mixed',
      monthlyIncomeReference: 8000,
      odometerKm: 50000,
    });

    expect(premium.partsScore).toBeLessThan(popular.partsScore);
    expect(premium.annualPartsCost).toBeGreaterThan(popular.annualPartsCost);
  });
});
