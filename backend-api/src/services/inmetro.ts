/**
 * services/inmetro.ts
 * Dados de consumo oficial Inmetro/PBE Veicular.
 * Fonte: https://www.gov.br/inmetro/pt-br/assuntos/avaliacao-da-conformidade/pbe-veicular
 *
 * Dataset seed: veículos mais vendidos no Brasil com dados públicos PBE.
 * Fase 2: importar CSV completo do Inmetro (794 versões).
 */

export type InmetroRecord = {
  brand: string;
  model: string;
  yearFrom: number;
  yearTo: number;
  engine: string;
  fuel: 'gasolina' | 'etanol' | 'flex' | 'diesel' | 'eletrico' | 'hibrido';
  urbanKmL: number;       // consumo urbano km/l (gasolina ou diesel ou elétrico)
  roadKmL: number;        // consumo rodoviário km/l
  ethanolUrbanKmL?: number;  // consumo urbano etanol (flex)
  ethanolRoadKmL?: number;   // consumo rodoviário etanol (flex)
};

export const inmetroData: InmetroRecord[] = [
  // CHEVROLET
  { brand: 'chevrolet', model: 'onix', yearFrom: 2020, yearTo: 2026, engine: '1.0 turbo', fuel: 'flex', urbanKmL: 13.2, roadKmL: 15.1, ethanolUrbanKmL: 9.2, ethanolRoadKmL: 10.6 },
  { brand: 'chevrolet', model: 'onix', yearFrom: 2012, yearTo: 2019, engine: '1.4', fuel: 'flex', urbanKmL: 11.6, roadKmL: 13.5, ethanolUrbanKmL: 8.1, ethanolRoadKmL: 9.4 },
  { brand: 'chevrolet', model: 'tracker', yearFrom: 2021, yearTo: 2026, engine: '1.2 turbo', fuel: 'flex', urbanKmL: 12.8, roadKmL: 15.2, ethanolUrbanKmL: 9.0, ethanolRoadKmL: 10.7 },
  { brand: 'chevrolet', model: 'prisma', yearFrom: 2013, yearTo: 2019, engine: '1.4', fuel: 'flex', urbanKmL: 11.4, roadKmL: 13.3, ethanolUrbanKmL: 8.0, ethanolRoadKmL: 9.3 },
  { brand: 'chevrolet', model: 'spin', yearFrom: 2012, yearTo: 2026, engine: '1.8', fuel: 'flex', urbanKmL: 10.3, roadKmL: 12.1, ethanolUrbanKmL: 7.2, ethanolRoadKmL: 8.5 },
  { brand: 'chevrolet', model: 's10', yearFrom: 2012, yearTo: 2026, engine: '2.8 diesel', fuel: 'diesel', urbanKmL: 9.8, roadKmL: 13.2 },

  // VOLKSWAGEN
  { brand: 'volkswagen', model: 'gol', yearFrom: 2008, yearTo: 2022, engine: '1.0', fuel: 'flex', urbanKmL: 11.0, roadKmL: 12.7, ethanolUrbanKmL: 7.7, ethanolRoadKmL: 8.9 },
  { brand: 'volkswagen', model: 'polo', yearFrom: 2018, yearTo: 2026, engine: '1.0 tsi', fuel: 'flex', urbanKmL: 13.0, roadKmL: 16.2, ethanolUrbanKmL: 9.1, ethanolRoadKmL: 11.3 },
  { brand: 'volkswagen', model: 'virtus', yearFrom: 2018, yearTo: 2026, engine: '1.0 tsi', fuel: 'flex', urbanKmL: 13.1, roadKmL: 16.3, ethanolUrbanKmL: 9.2, ethanolRoadKmL: 11.4 },
  { brand: 'volkswagen', model: 'nivus', yearFrom: 2020, yearTo: 2026, engine: '1.0 tsi', fuel: 'flex', urbanKmL: 13.5, roadKmL: 16.8, ethanolUrbanKmL: 9.5, ethanolRoadKmL: 11.8 },
  { brand: 'volkswagen', model: 'tcross', yearFrom: 2019, yearTo: 2026, engine: '1.0 tsi', fuel: 'flex', urbanKmL: 12.4, roadKmL: 15.7, ethanolUrbanKmL: 8.7, ethanolRoadKmL: 11.0 },
  { brand: 'volkswagen', model: 'saveiro', yearFrom: 2008, yearTo: 2026, engine: '1.6', fuel: 'flex', urbanKmL: 10.5, roadKmL: 12.0, ethanolUrbanKmL: 7.4, ethanolRoadKmL: 8.4 },
  { brand: 'volkswagen', model: 'fox', yearFrom: 2003, yearTo: 2018, engine: '1.6', fuel: 'flex', urbanKmL: 10.6, roadKmL: 12.2, ethanolUrbanKmL: 7.4, ethanolRoadKmL: 8.6 },

  // FIAT
  { brand: 'fiat', model: 'strada', yearFrom: 2021, yearTo: 2026, engine: '1.3', fuel: 'flex', urbanKmL: 11.4, roadKmL: 13.5, ethanolUrbanKmL: 8.0, ethanolRoadKmL: 9.5 },
  { brand: 'fiat', model: 'argo', yearFrom: 2017, yearTo: 2026, engine: '1.0', fuel: 'flex', urbanKmL: 13.3, roadKmL: 15.6, ethanolUrbanKmL: 9.3, ethanolRoadKmL: 10.9 },
  { brand: 'fiat', model: 'cronos', yearFrom: 2018, yearTo: 2026, engine: '1.3', fuel: 'flex', urbanKmL: 12.5, roadKmL: 14.7, ethanolUrbanKmL: 8.8, ethanolRoadKmL: 10.3 },
  { brand: 'fiat', model: 'mobi', yearFrom: 2016, yearTo: 2026, engine: '1.0', fuel: 'flex', urbanKmL: 12.8, roadKmL: 15.3, ethanolUrbanKmL: 9.0, ethanolRoadKmL: 10.7 },
  { brand: 'fiat', model: 'pulse', yearFrom: 2021, yearTo: 2026, engine: '1.0 turbo', fuel: 'flex', urbanKmL: 12.2, roadKmL: 14.8, ethanolUrbanKmL: 8.6, ethanolRoadKmL: 10.4 },
  { brand: 'fiat', model: 'toro', yearFrom: 2016, yearTo: 2026, engine: '2.0 diesel', fuel: 'diesel', urbanKmL: 10.4, roadKmL: 13.9 },
  { brand: 'fiat', model: 'palio', yearFrom: 1996, yearTo: 2016, engine: '1.0 / 1.4', fuel: 'flex', urbanKmL: 10.5, roadKmL: 12.3, ethanolUrbanKmL: 7.4, ethanolRoadKmL: 8.6 },
  { brand: 'fiat', model: 'uno', yearFrom: 2004, yearTo: 2014, engine: '1.0', fuel: 'flex', urbanKmL: 10.9, roadKmL: 12.5, ethanolUrbanKmL: 7.6, ethanolRoadKmL: 8.8 },

  // HYUNDAI
  { brand: 'hyundai', model: 'hb20', yearFrom: 2012, yearTo: 2026, engine: '1.0 turbo', fuel: 'flex', urbanKmL: 12.8, roadKmL: 15.0, ethanolUrbanKmL: 9.0, ethanolRoadKmL: 10.5 },
  { brand: 'hyundai', model: 'creta', yearFrom: 2017, yearTo: 2026, engine: '1.0 turbo', fuel: 'flex', urbanKmL: 12.0, roadKmL: 14.8, ethanolUrbanKmL: 8.4, ethanolRoadKmL: 10.4 },
  { brand: 'hyundai', model: 'i30', yearFrom: 2009, yearTo: 2016, engine: '1.6', fuel: 'gasolina', urbanKmL: 11.2, roadKmL: 13.8 },

  // TOYOTA
  { brand: 'toyota', model: 'corolla', yearFrom: 2015, yearTo: 2026, engine: '2.0 flex', fuel: 'flex', urbanKmL: 11.4, roadKmL: 13.6, ethanolUrbanKmL: 8.0, ethanolRoadKmL: 9.5 },
  { brand: 'toyota', model: 'hilux', yearFrom: 2012, yearTo: 2026, engine: '2.8 diesel', fuel: 'diesel', urbanKmL: 9.9, roadKmL: 13.4 },
  { brand: 'toyota', model: 'yaris', yearFrom: 2018, yearTo: 2026, engine: '1.5 flex', fuel: 'flex', urbanKmL: 13.0, roadKmL: 15.5, ethanolUrbanKmL: 9.1, ethanolRoadKmL: 10.9 },

  // HONDA
  { brand: 'honda', model: 'civic', yearFrom: 2017, yearTo: 2026, engine: '1.5 turbo', fuel: 'gasolina', urbanKmL: 11.9, roadKmL: 14.8 },
  { brand: 'honda', model: 'hr-v', yearFrom: 2015, yearTo: 2026, engine: '1.8 flex', fuel: 'flex', urbanKmL: 11.2, roadKmL: 13.5, ethanolUrbanKmL: 7.8, ethanolRoadKmL: 9.5 },
  { brand: 'honda', model: 'fit', yearFrom: 2009, yearTo: 2020, engine: '1.5 flex', fuel: 'flex', urbanKmL: 12.0, roadKmL: 14.4, ethanolUrbanKmL: 8.4, ethanolRoadKmL: 10.1 },

  // RENAULT
  { brand: 'renault', model: 'kwid', yearFrom: 2017, yearTo: 2026, engine: '1.0', fuel: 'flex', urbanKmL: 13.3, roadKmL: 15.4, ethanolUrbanKmL: 9.3, ethanolRoadKmL: 10.8 },
  { brand: 'renault', model: 'sandero', yearFrom: 2008, yearTo: 2022, engine: '1.6', fuel: 'flex', urbanKmL: 10.8, roadKmL: 12.8, ethanolUrbanKmL: 7.6, ethanolRoadKmL: 9.0 },
  { brand: 'renault', model: 'duster', yearFrom: 2012, yearTo: 2026, engine: '1.6 flex', fuel: 'flex', urbanKmL: 10.2, roadKmL: 12.1, ethanolUrbanKmL: 7.1, ethanolRoadKmL: 8.5 },

  // FORD
  { brand: 'ford', model: 'ka', yearFrom: 2015, yearTo: 2021, engine: '1.0 flex', fuel: 'flex', urbanKmL: 13.5, roadKmL: 15.9, ethanolUrbanKmL: 9.5, ethanolRoadKmL: 11.1 },
  { brand: 'ford', model: 'ecosport', yearFrom: 2013, yearTo: 2022, engine: '1.5 flex', fuel: 'flex', urbanKmL: 10.8, roadKmL: 13.2, ethanolUrbanKmL: 7.6, ethanolRoadKmL: 9.2 },

  // JEEP
  { brand: 'jeep', model: 'renegade', yearFrom: 2015, yearTo: 2026, engine: '1.3 turbo', fuel: 'flex', urbanKmL: 12.0, roadKmL: 14.5, ethanolUrbanKmL: 8.4, ethanolRoadKmL: 10.2 },
  { brand: 'jeep', model: 'compass', yearFrom: 2017, yearTo: 2026, engine: '2.0 diesel', fuel: 'diesel', urbanKmL: 11.4, roadKmL: 14.8 },

  // NISSAN
  { brand: 'nissan', model: 'kicks', yearFrom: 2016, yearTo: 2026, engine: '1.6 flex', fuel: 'flex', urbanKmL: 11.8, roadKmL: 14.0, ethanolUrbanKmL: 8.3, ethanolRoadKmL: 9.8 },
  { brand: 'nissan', model: 'march', yearFrom: 2011, yearTo: 2020, engine: '1.6 flex', fuel: 'flex', urbanKmL: 11.5, roadKmL: 13.7, ethanolUrbanKmL: 8.1, ethanolRoadKmL: 9.6 },

  // VOLKSWAGEN classicos
  { brand: 'volkswagen', model: 'fusca', yearFrom: 1960, yearTo: 1996, engine: '1.3 / 1.6', fuel: 'gasolina', urbanKmL: 9.5, roadKmL: 11.0 },
  { brand: 'chevrolet', model: 'corsa', yearFrom: 1993, yearTo: 2012, engine: '1.0 / 1.4', fuel: 'flex', urbanKmL: 10.2, roadKmL: 12.0, ethanolUrbanKmL: 7.1, ethanolRoadKmL: 8.4 },
];

function normalize(s: string): string {
  return s.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').trim();
}

export function lookupConsumption(
  brand: string,
  model: string,
  year: number
): InmetroRecord | null {
  const nb = normalize(brand);
  const nm = normalize(model);

  const candidates = inmetroData.filter(
    (r) =>
      normalize(r.brand) === nb &&
      normalize(r.model) === nm &&
      year >= r.yearFrom &&
      year <= r.yearTo
  );

  return candidates[0] ?? null;
}
