import { estimateFallbackPrice } from '../fipe';
import { MarketplaceOffer, OffersSearchFilters, OffersProvider } from './types';

// Curated Wikipedia article titles for each car model.
// Wikipedia PageImages API returns the main article photo — always the actual car.
const WIKI_TITLES: Record<string, string> = {
  'toyota:corolla':       'Toyota Corolla (E210)',
  'chevrolet:onix':       'Chevrolet Onix',
  'hyundai:hb20':         'Hyundai HB20',
  'honda:civic':          'Honda Civic (tenth generation)',
  'volkswagen:polo':      'Volkswagen Polo Mk6',
  'fiat:cronos':          'Fiat Cronos',
  'jeep:renegade':        'Jeep Renegade',
  'volkswagen:gol':       'Volkswagen Gol',
  'toyota:hilux':         'Toyota Hilux',
  'volkswagen:t-cross':   'Volkswagen T-Cross',
  'renault:kwid':         'Renault Kwid',
  'fiat:pulse':           'Fiat Pulse',
  'chevrolet:tracker':    'Chevrolet Tracker',
  'hyundai:creta':        'Hyundai Creta',
  'ford:ka':              'Ford Ka',
};

const _imageCache = new Map<string, string>();

async function getCarImage(brand: string, model: string): Promise<string> {
  const key = `${brand}:${model}`.toLowerCase();
  if (_imageCache.has(key)) return _imageCache.get(key)!;

  const wikiTitle = WIKI_TITLES[key];
  if (wikiTitle) {
    try {
      const params = new URLSearchParams({
        action: 'query',
        titles: wikiTitle,
        prop: 'pageimages',
        pithumbsize: '640',
        format: 'json',
        origin: '*',
      });
      const res = await fetch(`https://en.wikipedia.org/w/api.php?${params}`);
      const json = await res.json() as { query?: { pages?: Record<string, { thumbnail?: { source: string } }> } };
      const pages = Object.values(json.query?.pages ?? {});
      const thumb = pages[0]?.thumbnail?.source;
      if (thumb) {
        _imageCache.set(key, thumb);
        return thumb;
      }
    } catch {
      // fall through to next option
    }
  }

  // Fallback: Unsplash with more specific automotive query
  const fallback = `https://source.unsplash.com/640x400/?${encodeURIComponent(brand + ' ' + model + ' car exterior')}`;
  _imageCache.set(key, fallback);
  return fallback;
}

interface SeedDef {
  id: string; title: string; price: number;
  brand: string; model: string; year: number;
  km: number; city: string; region: string;
}

async function buildSeed(s: SeedDef): Promise<MarketplaceOffer> {
  const fipeEstimate = estimateFallbackPrice(s.model, s.year);
  const thumbnailUrl = await getCarImage(s.brand, s.model);
  return {
    id: s.id, title: s.title, price: s.price,
    fipeEstimate, fipeDiff: fipeEstimate - s.price,
    thumbnailUrl,
    listingUrl: '', region: s.region, city: s.city,
    km: s.km, brand: s.brand, model: s.model, year: s.year,
    source: 'local', sourceName: 'Base local',
  };
}

const SEED_DEFS: SeedDef[] = [
  { id: 'seed-001', title: 'Toyota Corolla XEi 2020',          price: 93900,  brand: 'Toyota',      model: 'Corolla',  year: 2020, km: 52000, city: 'Sao Paulo - SP',       region: 'Sao Paulo' },
  { id: 'seed-002', title: 'Chevrolet Onix LT 2021',           price: 67900,  brand: 'Chevrolet',   model: 'Onix',     year: 2021, km: 41000, city: 'Sao Paulo - SP',       region: 'Sao Paulo' },
  { id: 'seed-003', title: 'Hyundai HB20 Comfort 2019',        price: 58900,  brand: 'Hyundai',     model: 'HB20',     year: 2019, km: 63000, city: 'Santos - SP',          region: 'Santos' },
  { id: 'seed-004', title: 'Honda Civic EX 2018',              price: 88500,  brand: 'Honda',       model: 'Civic',    year: 2018, km: 70000, city: 'Curitiba - PR',        region: 'Curitiba' },
  { id: 'seed-005', title: 'Volkswagen Polo Comfortline 2021', price: 79900,  brand: 'Volkswagen',  model: 'Polo',     year: 2021, km: 34000, city: 'Belo Horizonte - MG',  region: 'Belo Horizonte' },
  { id: 'seed-006', title: 'Fiat Cronos Precision 2022',       price: 74900,  brand: 'Fiat',        model: 'Cronos',   year: 2022, km: 28000, city: 'Rio de Janeiro - RJ',  region: 'Rio de Janeiro' },
  { id: 'seed-007', title: 'Jeep Renegade Sport 2020',         price: 109900, brand: 'Jeep',        model: 'Renegade', year: 2020, km: 48000, city: 'Campinas - SP',        region: 'Campinas' },
  { id: 'seed-008', title: 'Volkswagen Gol 1.0 2018',          price: 42900,  brand: 'Volkswagen',  model: 'Gol',      year: 2018, km: 78000, city: 'Porto Alegre - RS',    region: 'Porto Alegre' },
  { id: 'seed-009', title: 'Toyota Hilux SRV 2019',            price: 188000, brand: 'Toyota',      model: 'Hilux',    year: 2019, km: 85000, city: 'Goiania - GO',         region: 'Goiania' },
  { id: 'seed-010', title: 'Volkswagen T-Cross Highline 2021', price: 119900, brand: 'Volkswagen',  model: 'T-Cross',  year: 2021, km: 31000, city: 'Brasilia - DF',        region: 'Brasilia' },
  { id: 'seed-011', title: 'Renault Kwid Zen 2022',            price: 44900,  brand: 'Renault',     model: 'Kwid',     year: 2022, km: 22000, city: 'Recife - PE',          region: 'Recife' },
  { id: 'seed-012', title: 'Fiat Pulse Drive 2022',            price: 89900,  brand: 'Fiat',        model: 'Pulse',    year: 2022, km: 19000, city: 'Salvador - BA',        region: 'Salvador' },
  { id: 'seed-013', title: 'Chevrolet Tracker Premier 2021',   price: 128900, brand: 'Chevrolet',   model: 'Tracker',  year: 2021, km: 37000, city: 'Sao Paulo - SP',       region: 'Sao Paulo' },
  { id: 'seed-014', title: 'Hyundai Creta Prestige 2020',      price: 124900, brand: 'Hyundai',     model: 'Creta',    year: 2020, km: 55000, city: 'Curitiba - PR',        region: 'Curitiba' },
  { id: 'seed-015', title: 'Ford Ka SE 2019',                  price: 47900,  brand: 'Ford',        model: 'Ka',       year: 2019, km: 61000, city: 'Fortaleza - CE',       region: 'Fortaleza' },
];

let _seededOffers: MarketplaceOffer[] | null = null;

async function getSeededOffers(): Promise<MarketplaceOffer[]> {
  if (_seededOffers) return _seededOffers;
  _seededOffers = await Promise.all(SEED_DEFS.map(buildSeed));
  return _seededOffers;
}

function containsNormalized(source: string, search?: string): boolean {
  if (!search) return true;
  return source.toLowerCase().includes(search.toLowerCase().trim());
}

function normalize(value?: string): string {
  return (value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function isGenericRegion(region?: string): boolean {
  const value = normalize(region);
  return (
    value.length === 0 ||
    value === 'brasil' ||
    value === 'br' ||
    value === 'nacional' ||
    value === 'todo brasil' ||
    value === 'all'
  );
}

export const seededOffersProvider: OffersProvider = {
  id: 'local',
  name: 'Base local',
  async healthCheck() {
    return {
      healthy: true,
      note: `seed_items_${SEED_DEFS.length}`,
    };
  },
  async search(filters: OffersSearchFilters): Promise<MarketplaceOffer[]> {
    const offers = await getSeededOffers();
    const region = normalize(filters.region);

    const matchesWithoutRegion = offers.filter((offer) => {
      const matchesBrand = containsNormalized(offer.brand, filters.brand);
      const matchesModel = containsNormalized(offer.model, filters.model);
      return matchesBrand && matchesModel;
    });

    if (isGenericRegion(region)) {
      return matchesWithoutRegion;
    }

    const regionMatches = matchesWithoutRegion.filter((offer) => {
      return (
        normalize(offer.region).includes(region) ||
        normalize(offer.city).includes(region)
      );
    });

    // If strict region matching returns too few local fallback options,
    // keep user query useful by backfilling with nationwide brand/model matches.
    if (regionMatches.length > 0 || (filters.brand || filters.model)) {
      return regionMatches.length > 0 ? regionMatches : matchesWithoutRegion;
    }

    return offers.filter((offer) => {
      const matchesRegion =
        region.length < 3 ||
        normalize(offer.region).includes(region) ||
        normalize(offer.city).includes(region);
      const matchesBrand = containsNormalized(offer.brand, filters.brand);
      const matchesModel = containsNormalized(offer.model, filters.model);
      return matchesRegion && matchesBrand && matchesModel;
    });
  },
};