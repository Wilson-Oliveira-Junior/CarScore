export type AnalysisInput = {
  vehicleLabel: string;
  year: number;
  askingPrice: number;
  kmPerMonth: number;
  kmPerLiter: number;
  fuelPricePerLiter: number;
  maintenanceMonthly: number;
};

export function analyze(input: AnalysisInput) {
  const data = input;

  const fuelMonthly = (data.kmPerMonth / data.kmPerLiter) * data.fuelPricePerLiter;
  const monthlyTotal = fuelMonthly + data.maintenanceMonthly;

  // Pillar 1: priceScore
  // Heuristic reference price: baseline 60k depreciating 4% per year
  const currentYear = new Date().getFullYear();
  const age = Math.max(0, currentYear - data.year);
  const referencePrice = Math.max(3000, 60000 * Math.pow(0.96, age));
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

  // New weights: price more important
  const weights = {
    price: 0.4,
    fuel: 0.25,
    maintenance: 0.2,
    adequacy: 0.15,
  };

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
  };
}
