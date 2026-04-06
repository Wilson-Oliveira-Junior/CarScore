export type UsageProfile = 'urban' | 'mixed' | 'highway';

export type PartCatalogItem = {
  key: string;
  label: string;
  minPrice: number;
  avgPrice: number;
  maxPrice: number;
  annualCostEstimate: number;
};

export type PartsEstimateInput = {
  brand: string;
  model: string;
  year: number;
  region?: string;
  odometerKm?: number;
  usageProfile?: UsageProfile;
  monthlyIncomeReference?: number;
};

export type PartsEstimateResult = {
  input: {
    brand: string;
    model: string;
    year: number;
    region: string;
    odometerKm: number;
    usageProfile: UsageProfile;
    monthlyIncomeReference: number;
  };
  basket: PartCatalogItem[];
  annualPartsCost: number;
  monthlyPartsCost: number;
  ipp: number;
  partsScore: number;
  label: 'baixo_risco_pecas' | 'moderado_risco_pecas' | 'alto_risco_pecas';
  outlierParts: string[];
  source: 'local_seed_v1' | 'mercadolivre_blended_v1';
  sourceDetails?: {
    provider: 'mercadolivre';
    marketQuotesUsed: number;
    fallbackUsed: boolean;
  };
};

type BasePart = {
  key: string;
  label: string;
  baseMin: number;
  baseAvg: number;
  baseMax: number;
  intervalKm: number;
};

const BASE_PARTS: BasePart[] = [
  { key: 'brake_kit', label: 'Jogo de freio', baseMin: 350, baseAvg: 520, baseMax: 760, intervalKm: 30000 },
  { key: 'clutch_kit', label: 'Kit embreagem', baseMin: 950, baseAvg: 1450, baseMax: 2400, intervalKm: 90000 },
  { key: 'shock_absorber_set', label: 'Amortecedores', baseMin: 1200, baseAvg: 1800, baseMax: 3200, intervalKm: 70000 },
  { key: 'tires_set', label: 'Pneu (jogo)', baseMin: 1400, baseAvg: 2200, baseMax: 3800, intervalKm: 45000 },
  { key: 'battery', label: 'Bateria', baseMin: 420, baseAvg: 680, baseMax: 1200, intervalKm: 50000 },
  { key: 'fuel_pump', label: 'Bomba de combustivel', baseMin: 520, baseAvg: 900, baseMax: 1650, intervalKm: 120000 },
  { key: 'belt_and_tensioner', label: 'Correia e tensor', baseMin: 450, baseAvg: 760, baseMax: 1400, intervalKm: 70000 },
];

const BRAND_MULTIPLIER_RULES: Array<{ pattern: RegExp; multiplier: number }> = [
  { pattern: /bmw|mercedes|audi|volvo|land rover|porsche|jaguar/i, multiplier: 1.55 },
  { pattern: /jeep|hyundai|kia|nissan|mitsubishi|peugeot|citroen|renault|toyota|honda/i, multiplier: 1.2 },
  { pattern: /fiat|chevrolet|volkswagen|vw|ford|gm/i, multiplier: 1.0 },
];

const USAGE_ANNUAL_KM: Record<UsageProfile, number> = {
  urban: 12000,
  mixed: 15000,
  highway: 22000,
};

const USAGE_MULTIPLIER: Record<UsageProfile, number> = {
  urban: 1.1,
  mixed: 1.0,
  highway: 0.95,
};

const REGION_MULTIPLIER_RULES: Array<{ pattern: RegExp; multiplier: number }> = [
  { pattern: /sp|sao paulo|rio de janeiro|rj|df|brasilia/i, multiplier: 1.1 },
  { pattern: /norte|nordeste|centro-oeste/i, multiplier: 1.05 },
  { pattern: /sul|sudeste/i, multiplier: 1.0 },
];

const ML_BASE = 'https://api.mercadolibre.com';
const PARTS_CACHE_TTL_MS = 10 * 60 * 1000;

type MercadoLivreSearchResponse = {
  results?: Array<{
    price?: number;
  }>;
};

const marketPriceCache = new Map<string, { prices: number[]; fetchedAt: number }>();

function roundCurrency(value: number): number {
  return Math.round(value * 100) / 100;
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function resolveBrandMultiplier(brand: string): number {
  const normalized = brand.trim();
  const found = BRAND_MULTIPLIER_RULES.find((rule) => rule.pattern.test(normalized));
  return found ? found.multiplier : 1.1;
}

function resolveRegionMultiplier(region?: string): number {
  if (!region) return 1.0;
  const normalized = region.trim();
  const found = REGION_MULTIPLIER_RULES.find((rule) => rule.pattern.test(normalized));
  return found ? found.multiplier : 1.0;
}

function resolveIncomeReference(region?: string): number {
  if (!region) return 3000;
  const normalized = region.toLowerCase();
  if (/sao paulo|sp|rio de janeiro|rj|brasilia|df/.test(normalized)) return 4200;
  if (/sul|sudeste/.test(normalized)) return 3600;
  if (/centro-oeste|norte|nordeste/.test(normalized)) return 3200;
  return 3000;
}

function scoreFromIpp(ipp: number): number {
  if (ipp <= 0.35) return 100;
  if (ipp >= 2.2) return 0;
  return Math.round(((2.2 - ipp) / (2.2 - 0.35)) * 100);
}

function labelFromScore(score: number): PartsEstimateResult['label'] {
  if (score >= 70) return 'baixo_risco_pecas';
  if (score >= 45) return 'moderado_risco_pecas';
  return 'alto_risco_pecas';
}

function resolveUsageProfile(profile?: UsageProfile): UsageProfile {
  if (!profile) return 'mixed';
  return profile;
}

function resolveYearMultiplier(year: number): number {
  const age = Math.max(0, new Date().getFullYear() - year);
  return clamp(1 + age * 0.015, 1, 1.35);
}

function resolveOdometerMultiplier(odometerKm: number): number {
  if (odometerKm <= 40000) return 1;
  return clamp(1 + (odometerKm - 40000) / 200000, 1, 1.4);
}

function normalizeSpace(value: string): string {
  return value.replace(/\s+/g, ' ').trim();
}

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  if (sorted.length === 1) return sorted[0];
  const idx = (sorted.length - 1) * p;
  const lo = Math.floor(idx);
  const hi = Math.ceil(idx);
  if (lo === hi) return sorted[lo];
  const weight = idx - lo;
  return sorted[lo] * (1 - weight) + sorted[hi] * weight;
}

async function fetchMercadoLivrePartPrices(
  input: PartsEstimateInput,
  item: PartCatalogItem
): Promise<number[]> {
  const query = normalizeSpace(`${item.label} ${input.brand} ${input.model}`);
  const cacheKey = JSON.stringify({
    q: query,
    region: input.region ?? 'nacional',
    year: input.year,
  });
  const cached = marketPriceCache.get(cacheKey);
  if (cached && Date.now() - cached.fetchedAt < PARTS_CACHE_TTL_MS) {
    return cached.prices;
  }

  const url =
    `${ML_BASE}/sites/MLB/search` +
    `?q=${encodeURIComponent(query)}` +
    '&limit=20' +
    '&condition=new';

  const response = await fetch(url, {
    headers: { Accept: 'application/json' },
    signal: AbortSignal.timeout(7000),
  });

  if (!response.ok) {
    throw new Error(`ml_http_${response.status}`);
  }

  const data = (await response.json()) as MercadoLivreSearchResponse;
  const prices = (data.results ?? [])
    .map((result) => Number(result.price))
    .filter((price) => Number.isFinite(price) && price >= 20 && price <= 200000)
    .sort((a, b) => a - b);

  marketPriceCache.set(cacheKey, { prices, fetchedAt: Date.now() });
  return prices;
}

function blendCatalogWithMarket(
  localBasket: PartCatalogItem[],
  marketByKey: Map<string, number[]>
): { basket: PartCatalogItem[]; marketQuotesUsed: number } {
  let marketQuotesUsed = 0;

  const basket = localBasket.map((item) => {
    const marketPrices = marketByKey.get(item.key) ?? [];
    if (marketPrices.length < 4) {
      return item;
    }

    const marketMin = percentile(marketPrices, 0.1);
    const marketAvg = percentile(marketPrices, 0.5);
    const marketMax = percentile(marketPrices, 0.9);

    const mergedMin = roundCurrency((item.minPrice + marketMin * 2) / 3);
    const mergedAvg = roundCurrency((item.avgPrice + marketAvg * 2) / 3);
    const mergedMax = roundCurrency((item.maxPrice + marketMax * 2) / 3);

    const replacementFactor = item.avgPrice > 0 ? item.annualCostEstimate / item.avgPrice : 0.2;
    const annualCostEstimate = roundCurrency(mergedAvg * Math.max(0.2, replacementFactor));

    marketQuotesUsed += marketPrices.length;

    return {
      ...item,
      minPrice: mergedMin,
      avgPrice: mergedAvg,
      maxPrice: mergedMax,
      annualCostEstimate,
    };
  });

  return { basket, marketQuotesUsed };
}

async function getPartsCatalogWithMarket(input: PartsEstimateInput): Promise<{
  basket: PartCatalogItem[];
  source: PartsEstimateResult['source'];
  sourceDetails?: PartsEstimateResult['sourceDetails'];
}> {
  const localBasket = getPartsCatalog(input);

  const settled = await Promise.allSettled(
    localBasket.map(async (item) => {
      const prices = await fetchMercadoLivrePartPrices(input, item);
      return { key: item.key, prices };
    })
  );

  const marketByKey = new Map<string, number[]>();
  for (const item of settled) {
    if (item.status !== 'fulfilled') continue;
    marketByKey.set(item.value.key, item.value.prices);
  }

  const { basket, marketQuotesUsed } = blendCatalogWithMarket(localBasket, marketByKey);
  const partsWithQuotes = basket.filter((part) => (marketByKey.get(part.key)?.length ?? 0) >= 4).length;

  if (partsWithQuotes < 3) {
    return {
      basket: localBasket,
      source: 'local_seed_v1',
      sourceDetails: {
        provider: 'mercadolivre',
        marketQuotesUsed,
        fallbackUsed: true,
      },
    };
  }

  return {
    basket,
    source: 'mercadolivre_blended_v1',
    sourceDetails: {
      provider: 'mercadolivre',
      marketQuotesUsed,
      fallbackUsed: false,
    },
  };
}

export function getPartsCatalog(input: PartsEstimateInput): PartCatalogItem[] {
  const usageProfile = resolveUsageProfile(input.usageProfile);
  const regionMultiplier = resolveRegionMultiplier(input.region);
  const brandMultiplier = resolveBrandMultiplier(input.brand);
  const yearMultiplier = resolveYearMultiplier(input.year);
  const odometerMultiplier = resolveOdometerMultiplier(input.odometerKm ?? 60000);
  const usageMultiplier = USAGE_MULTIPLIER[usageProfile];

  const globalMultiplier =
    brandMultiplier * regionMultiplier * yearMultiplier * odometerMultiplier * usageMultiplier;

  const annualKm = USAGE_ANNUAL_KM[usageProfile];

  return BASE_PARTS.map((item) => {
    const minPrice = roundCurrency(item.baseMin * globalMultiplier);
    const avgPrice = roundCurrency(item.baseAvg * globalMultiplier);
    const maxPrice = roundCurrency(item.baseMax * globalMultiplier);

    const replacementFactor = Math.max(
      0.2,
      annualKm / item.intervalKm + Math.max(0, (input.odometerKm ?? 60000) - 90000) / 250000
    );

    const annualCostEstimate = roundCurrency(avgPrice * replacementFactor);

    return {
      key: item.key,
      label: item.label,
      minPrice,
      avgPrice,
      maxPrice,
      annualCostEstimate,
    };
  });
}

export function estimatePartsRisk(input: PartsEstimateInput): PartsEstimateResult {
  const usageProfile = resolveUsageProfile(input.usageProfile);
  const monthlyIncomeReference = input.monthlyIncomeReference && input.monthlyIncomeReference > 0
    ? input.monthlyIncomeReference
    : resolveIncomeReference(input.region);
  const basket = getPartsCatalog({
    ...input,
    usageProfile,
    monthlyIncomeReference,
  });

  const annualPartsCost = roundCurrency(
    basket.reduce((sum, item) => sum + item.annualCostEstimate, 0)
  );
  const monthlyPartsCost = roundCurrency(annualPartsCost / 12);
  const ipp = roundCurrency(annualPartsCost / monthlyIncomeReference);
  const partsScore = scoreFromIpp(ipp);
  const label = labelFromScore(partsScore);

  const outlierThreshold = annualPartsCost * 0.22;
  const outlierParts = basket
    .filter((item) => item.annualCostEstimate >= outlierThreshold)
    .map((item) => item.label);

  return {
    input: {
      brand: input.brand,
      model: input.model,
      year: input.year,
      region: input.region ?? 'nacional',
      odometerKm: input.odometerKm ?? 60000,
      usageProfile,
      monthlyIncomeReference,
    },
    basket,
    annualPartsCost,
    monthlyPartsCost,
    ipp,
    partsScore,
    label,
    outlierParts,
    source: 'local_seed_v1',
  };
}

export async function estimatePartsRiskWithProviders(
  input: PartsEstimateInput
): Promise<PartsEstimateResult> {
  const usageProfile = resolveUsageProfile(input.usageProfile);
  const monthlyIncomeReference =
    input.monthlyIncomeReference && input.monthlyIncomeReference > 0
      ? input.monthlyIncomeReference
      : resolveIncomeReference(input.region);

  const resolved = await getPartsCatalogWithMarket({
    ...input,
    usageProfile,
    monthlyIncomeReference,
  });

  const annualPartsCost = roundCurrency(
    resolved.basket.reduce((sum, item) => sum + item.annualCostEstimate, 0)
  );
  const monthlyPartsCost = roundCurrency(annualPartsCost / 12);
  const ipp = roundCurrency(annualPartsCost / monthlyIncomeReference);
  const partsScore = scoreFromIpp(ipp);
  const label = labelFromScore(partsScore);

  const outlierThreshold = annualPartsCost * 0.22;
  const outlierParts = resolved.basket
    .filter((item) => item.annualCostEstimate >= outlierThreshold)
    .map((item) => item.label);

  return {
    input: {
      brand: input.brand,
      model: input.model,
      year: input.year,
      region: input.region ?? 'nacional',
      odometerKm: input.odometerKm ?? 60000,
      usageProfile,
      monthlyIncomeReference,
    },
    basket: resolved.basket,
    annualPartsCost,
    monthlyPartsCost,
    ipp,
    partsScore,
    label,
    outlierParts,
    source: resolved.source,
    sourceDetails: resolved.sourceDetails,
  };
}
