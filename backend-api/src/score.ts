export type AnalysisInput = {
  vehicleLabel: string;
  year: number;
  askingPrice: number;
  kmPerMonth: number;
  kmPerLiter: number;
  fuelPricePerLiter: number;
  maintenanceMonthly: number;
  /** Preço de referência FIPE real (quando disponível). Substitui a heurística interna. */
  fipeReferencePrice?: number;
};

export type ScoreWeights = {
  price: number;
  fuel: number;
  maintenance: number;
  adequacy: number;
};

export const defaultWeights: ScoreWeights = {
  price: 0.4,
  fuel: 0.25,
  maintenance: 0.2,
  adequacy: 0.15,
};

export function normalizeWeights(input: ScoreWeights): ScoreWeights {
  const sum = input.price + input.fuel + input.maintenance + input.adequacy;
  if (sum <= 0) {
    return defaultWeights;
  }
  return {
    price: input.price / sum,
    fuel: input.fuel / sum,
    maintenance: input.maintenance / sum,
    adequacy: input.adequacy / sum,
  };
}

export function analyze(input: AnalysisInput, customWeights: ScoreWeights = defaultWeights) {
  const data = input;
  const weights = normalizeWeights(customWeights);

  const fuelMonthly = (data.kmPerMonth / data.kmPerLiter) * data.fuelPricePerLiter;
  const monthlyTotal = fuelMonthly + data.maintenanceMonthly;

  // Pillar 1: priceScore
  // Usa preço FIPE real quando disponível; caso contrário, heurística de depreciação.
  const currentYear = new Date().getFullYear();
  const age = Math.max(0, currentYear - data.year);
  const referencePrice = data.fipeReferencePrice ?? Math.max(3000, 60000 * Math.pow(0.96, age));
  const priceSource = data.fipeReferencePrice ? 'fipe' : 'heuristic';
  const priceRatio = data.askingPrice / referencePrice;
  let priceScore = 0;
  if (priceRatio <= 0.8) priceScore = 100;
  else if (priceRatio >= 1.2) priceScore = 0;
  else priceScore = Math.round(((1.2 - priceRatio) / (1.2 - 0.8)) * 100);

  // Pillar 2: fuelScore
  let fuelScore = 0;
  if (fuelMonthly <= 80) fuelScore = 100;
  else if (fuelMonthly >= 800) fuelScore = 0;
  else fuelScore = Math.round(((800 - fuelMonthly) / (800 - 80)) * 100);

  // Pillar 3: maintenanceScore
  let maintenanceScore = 0;
  if (data.maintenanceMonthly <= 50) maintenanceScore = 100;
  else if (data.maintenanceMonthly >= 800) maintenanceScore = 0;
  else maintenanceScore = Math.round(((800 - data.maintenanceMonthly) / (800 - 50)) * 100);

  // Pillar 4: adequacyScore
  let adequacyScore = 100;
  adequacyScore -= Math.max(0, Math.min(40, (data.kmPerMonth - 800) / 20));
  adequacyScore -= Math.max(0, Math.min(40, (8 - data.kmPerLiter) * 5));
  adequacyScore = Math.round(Math.max(0, Math.min(100, adequacyScore)));

  const finalScore = Math.round(
    priceScore * weights.price +
      fuelScore * weights.fuel +
      maintenanceScore * weights.maintenance +
      adequacyScore * weights.adequacy
  );

  let label = 'nao_recomendado';
  if (finalScore >= 80) label = 'compra_saudavel';
  else if (finalScore >= 60) label = 'viavel_com_atencao';
  else if (finalScore >= 40) label = 'alto_custo_para_perfil';

  return {
    fuelMonthly,
    monthlyTotal,
    pillars: {
      priceScore,
      fuelScore,
      maintenanceScore,
      adequacyScore,
    },
    weights,
    finalScore,
    label,
    meta: {
      referencePrice,
      priceSource,
    },
  };
}
