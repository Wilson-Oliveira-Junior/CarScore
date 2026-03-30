/**
 * services/fipe.ts
 * Integração multi-provedor da FIPE.
 * Provedor primário: BrasilAPI
 * Provedor secundário: Parallelum/FIPE
 * Fallback final: base local derivada do Inmetro
 */

import { inmetroData } from './inmetro';

const BRASIL_API_BASE = 'https://brasilapi.com.br/api/fipe/v1';
const PARALLELUM_BASE = 'https://parallelum.com.br/fipe/api/v1/carros';

export type FipeSource = 'brasilapi' | 'parallelum' | 'local';

export type FipeBrand = {
  nome: string;
  codigo: string;
};

export type FipeModel = {
  nome: string;
  codigo: number;
};

export type FipeYear = {
  nome: string;
  codigo: string;
};

export type FipePrice = {
  valor: string;         // ex.: "R$ 72.100,00"
  marca: string;
  modelo: string;
  anoModelo: number;
  combustivel: string;
  codigoFipe: string;
  mesReferencia: string;
  tipoVeiculo: number;
  siglaCombustivel: string;
  dataConsulta: string;
};

export type FipeResolvedPrice = {
  price: FipePrice;
  source: FipeSource;
  sourceName: string;
  isFallback: boolean;
};

async function fetchJson<T>(url: string): Promise<T> {
  const res = await fetch(url, {
    headers: { 'Accept': 'application/json' },
    signal: AbortSignal.timeout(8000),
  });
  if (!res.ok) {
    throw new Error(`FIPE API error ${res.status}: ${url}`);
  }
  return res.json() as Promise<T>;
}

function sourceName(source: FipeSource): string {
  if (source == 'brasilapi') return 'BrasilAPI';
  if (source == 'parallelum') return 'Parallelum/FIPE';
  return 'Base local';
}

type FallbackBrand = {
  code: string;
  name: string;
};

type FallbackModel = {
  code: number;
  name: string;
};

type FallbackVehicle = {
  brandCode: string;
  brandName: string;
  modelCode: number;
  modelName: string;
  yearFrom: number;
  yearTo: number;
  fuel: string;
};

function titleCase(value: string): string {
  return value
    .split(/\s+/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(' ');
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

const fallbackBrands: FallbackBrand[] = Array.from(
  new Set(inmetroData.map((item) => normalize(item.brand)))
)
  .sort((a, b) => a.localeCompare(b))
  .map((brand) => ({
    code: `local-${brand}`,
    name: titleCase(brand),
  }));

const fallbackVehicles: FallbackVehicle[] = inmetroData.map((item) => {
  const brandCode = `local-${normalize(item.brand)}`;
  const modelKey = `${brandCode}:${normalize(item.model)}`;
  const modelCode = Array.from(
    new Set(
      inmetroData
        .map((entry) => `${`local-${normalize(entry.brand)}`}:${normalize(entry.model)}`)
        .sort((a, b) => a.localeCompare(b))
    )
  ).indexOf(modelKey) + 1;

  return {
    brandCode,
    brandName: titleCase(normalize(item.brand)),
    modelCode,
    modelName: titleCase(normalize(item.model)),
    yearFrom: item.yearFrom,
    yearTo: item.yearTo,
    fuel: item.fuel,
  };
});

function getFallbackModels(brandCode: string): FallbackModel[] {
  const models = fallbackVehicles
    .filter((item) => item.brandCode === brandCode)
    .map((item) => ({ code: item.modelCode, name: item.modelName }));

  const dedup = new Map<number, FallbackModel>();
  for (const model of models) {
    dedup.set(model.code, model);
  }
  return Array.from(dedup.values()).sort((a, b) => a.name.localeCompare(b.name));
}

function getFallbackYears(brandCode: string, modelCode: number): FipeYear[] {
  const vehicle = fallbackVehicles.find(
    (item) => item.brandCode === brandCode && item.modelCode === modelCode
  );
  if (!vehicle) return [];

  const years: FipeYear[] = [];
  for (let year = vehicle.yearTo; year >= vehicle.yearFrom; year -= 1) {
    years.push({ nome: `${year} Gasolina`, codigo: `${year}-1` });
  }
  return years;
}

export function estimateFallbackPrice(modelName: string, year: number): number {
  const currentYear = new Date().getFullYear();
  const age = Math.max(0, currentYear - year);
  const model = normalize(modelName);

  let basePrice = 65000;
  if (model.includes('corolla')) basePrice = 118000;
  else if (model.includes('civic')) basePrice = 128000;
  else if (model.includes('hilux')) basePrice = 210000;
  else if (model.includes('compass')) basePrice = 165000;
  else if (model.includes('renegade')) basePrice = 118000;
  else if (model.includes('tracker') || model.includes('creta') || model.includes('hr-v')) basePrice = 132000;
  else if (model.includes('onix') || model.includes('hb20') || model.includes('polo') || model.includes('yaris')) basePrice = 86000;
  else if (model.includes('gol') || model.includes('uno') || model.includes('palio') || model.includes('ka') || model.includes('kwid')) basePrice = 58000;

  const estimated = Math.max(18000, Math.round(basePrice * Math.pow(0.92, age)));
  return estimated;
}

function formatBrl(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL',
  }).format(value);
}

async function getBrandsFromParallelum(): Promise<FipeBrand[]> {
  type ParallelumBrand = { codigo: string; nome: string };
  const items = await fetchJson<ParallelumBrand[]>(`${PARALLELUM_BASE}/marcas`);
  return items.map((item) => ({ codigo: item.codigo, nome: item.nome }));
}

async function getModelsFromParallelum(brandCode: string): Promise<FipeModel[]> {
  type ParallelumModel = { codigo: number | string; nome: string };
  type ParallelumModelsResponse = { modelos: ParallelumModel[] };
  const data = await fetchJson<ParallelumModelsResponse>(
    `${PARALLELUM_BASE}/marcas/${brandCode}/modelos`
  );
  return (data.modelos ?? []).map((item) => ({
    codigo: Number.parseInt(String(item.codigo), 10),
    nome: item.nome,
  }));
}

async function getYearsFromParallelum(brandCode: string, modelCode: number): Promise<FipeYear[]> {
  type ParallelumYear = { codigo: string; nome: string };
  const items = await fetchJson<ParallelumYear[]>(
    `${PARALLELUM_BASE}/marcas/${brandCode}/modelos/${modelCode}/anos`
  );
  return items.map((item) => ({ codigo: item.codigo, nome: item.nome }));
}

async function getPriceFromParallelum(
  brandCode: string,
  modelCode: number,
  yearCode: string
): Promise<FipePrice> {
  type ParallelumPrice = {
    Valor: string;
    Marca: string;
    Modelo: string;
    AnoModelo: number;
    Combustivel: string;
    CodigoFipe: string;
    MesReferencia: string;
    TipoVeiculo: number;
    SiglaCombustivel: string;
  };

  const item = await fetchJson<ParallelumPrice>(
    `${PARALLELUM_BASE}/marcas/${brandCode}/modelos/${modelCode}/anos/${yearCode}`
  );

  return {
    valor: item.Valor,
    marca: item.Marca,
    modelo: item.Modelo,
    anoModelo: item.AnoModelo,
    combustivel: item.Combustivel,
    codigoFipe: item.CodigoFipe,
    mesReferencia: item.MesReferencia,
    tipoVeiculo: item.TipoVeiculo,
    siglaCombustivel: item.SiglaCombustivel,
    dataConsulta: new Date().toISOString(),
  };
}

export async function getBrands(): Promise<FipeBrand[]> {
  if (fallbackBrands.length === 0) {
    return [];
  }

  try {
    return await fetchJson<FipeBrand[]>(`${BRASIL_API_BASE}/brands/cars`);
  } catch {
    try {
      return await getBrandsFromParallelum();
    } catch {
      return fallbackBrands.map((item) => ({ nome: item.name, codigo: item.code }));
    }
  }
}

export async function getModels(brandCode: string): Promise<FipeModel[]> {
  type Resp = { modelos: FipeModel[] };
  if (brandCode.startsWith('local-')) {
    return getFallbackModels(brandCode).map((item) => ({
      nome: item.name,
      codigo: item.code,
    }));
  }

  try {
    const data = await fetchJson<Resp>(`${BRASIL_API_BASE}/vehicles/${brandCode}`);
    return data.modelos ?? [];
  } catch {
    try {
      return await getModelsFromParallelum(brandCode);
    } catch {
      return getFallbackModels(brandCode).map((item) => ({
        nome: item.name,
        codigo: item.code,
      }));
    }
  }
}

export async function getYears(brandCode: string, modelCode: number): Promise<FipeYear[]> {
  if (brandCode.startsWith('local-')) {
    return getFallbackYears(brandCode, modelCode);
  }

  try {
    return await fetchJson<FipeYear[]>(`${BRASIL_API_BASE}/vehicles/${brandCode}/${modelCode}`);
  } catch {
    try {
      return await getYearsFromParallelum(brandCode, modelCode);
    } catch {
      return getFallbackYears(brandCode, modelCode);
    }
  }
}

export async function getPriceWithSource(
  brandCode: string,
  modelCode: number,
  yearCode: string
): Promise<FipeResolvedPrice> {
  if (!brandCode.startsWith('local-')) {
    try {
      const price = await fetchJson<FipePrice>(
        `${BRASIL_API_BASE}/vehicles/${brandCode}/${modelCode}/${yearCode}`
      );
      return {
        price,
        source: 'brasilapi',
        sourceName: sourceName('brasilapi'),
        isFallback: false,
      };
    } catch {
      try {
        const price = await getPriceFromParallelum(brandCode, modelCode, yearCode);
        return {
          price,
          source: 'parallelum',
          sourceName: sourceName('parallelum'),
          isFallback: true,
        };
      } catch {
        // cai no fallback local abaixo
      }
    }
  }

  const vehicle = fallbackVehicles.find(
    (item) => item.brandCode === brandCode && item.modelCode === modelCode
  );
  if (!vehicle) {
    throw new Error('Fallback FIPE data unavailable for requested vehicle.');
  }

  const year = Number.parseInt(yearCode.split('-')[0], 10) || vehicle.yearTo;
  const estimatedPrice = estimateFallbackPrice(vehicle.modelName, year);

  return {
    price: {
      valor: formatBrl(estimatedPrice),
      marca: vehicle.brandName,
      modelo: vehicle.modelName,
      anoModelo: year,
      combustivel: vehicle.fuel,
      codigoFipe: `LOCAL-${brandCode}-${modelCode}-${year}`,
      mesReferencia: 'base local estimada',
      tipoVeiculo: 1,
      siglaCombustivel: vehicle.fuel.slice(0, 1).toUpperCase(),
      dataConsulta: new Date().toISOString(),
    },
    source: 'local',
    sourceName: sourceName('local'),
    isFallback: true,
  };
}

export async function getPrice(
  brandCode: string,
  modelCode: number,
  yearCode: string
): Promise<FipePrice> {
  const resolved = await getPriceWithSource(brandCode, modelCode, yearCode);
  return resolved.price;
}

/**
 * Converte "R$ 72.100,00" → 72100.00
 */
export function parseFipeValue(valor: string): number {
  const cleaned = valor.replace(/R\$\s*/g, '').replace(/\./g, '').replace(',', '.');
  return parseFloat(cleaned);
}
