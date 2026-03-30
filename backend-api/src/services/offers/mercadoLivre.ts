import { estimateFallbackPrice } from '../fipe';
import { MarketplaceOffer, OffersSearchFilters, OffersProvider } from './types';

const ML_BASE = 'https://api.mercadolibre.com';
const ML_CARS_CATEGORY = 'MLB174200';
const CACHE_TTL_MS = 10 * 60 * 1000;

type RawAttr = { id: string; value_name: string | null };

type RawResult = {
  id: string;
  title: string;
  price: number;
  thumbnail: string;
  permalink: string;
  seller_address?: {
    state?: { name?: string };
    city?: { name?: string };
  };
  attributes?: RawAttr[];
};

type SearchResponse = {
  results?: RawResult[];
};

const cache = new Map<string, { offers: MarketplaceOffer[]; fetchedAt: number }>();

function getAttr(attributes: RawAttr[], id: string): string | null {
  return attributes.find((a) => a.id === id)?.value_name ?? null;
}

function cleanThumbUrl(url: string): string {
  return url.replace('http://', 'https://').replace(/-[A-Z]\.jpg$/, '-O.jpg');
}

function buildQuery(filters: OffersSearchFilters): string {
  return [filters.brand, filters.model, filters.region]
    .map((item) => item?.trim())
    .filter((item): item is string => Boolean(item))
    .join(' ');
}

export const mercadoLivreProvider: OffersProvider = {
  id: 'mercadolivre',
  name: 'Mercado Livre',
  async search(filters: OffersSearchFilters): Promise<MarketplaceOffer[]> {
    const query = buildQuery(filters);
    const cacheKey = JSON.stringify({
      q: query,
      limit: filters.limit,
      maxPrice: filters.maxPrice,
    });

    const cached = cache.get(cacheKey);
    if (cached && Date.now() - cached.fetchedAt < CACHE_TTL_MS) {
      return cached.offers;
    }

    const searchUrl =
      `${ML_BASE}/sites/MLB/search` +
      `?category=${ML_CARS_CATEGORY}` +
      `&q=${encodeURIComponent(query || filters.region)}` +
      `&limit=${filters.limit}` +
      `&condition=used` +
      `&sort=price_asc` +
      (filters.maxPrice ? `&price=0-${Math.round(filters.maxPrice)}` : '');

    const res = await fetch(searchUrl, {
      headers: { Accept: 'application/json' },
      signal: AbortSignal.timeout(10000),
    });
    if (!res.ok) {
      throw new Error(`ML API ${res.status}`);
    }

    const data = (await res.json()) as SearchResponse;
    const offers = (data.results ?? []).map((item): MarketplaceOffer => {
      const attrs = item.attributes ?? [];
      const brand = getAttr(attrs, 'BRAND') ?? '';
      const model = getAttr(attrs, 'MODEL') ?? '';
      const yearStr = getAttr(attrs, 'VEHICLE_YEAR');
      const kmStr = getAttr(attrs, 'KILOMETERS');
      const year = yearStr ? Number.parseInt(yearStr, 10) : new Date().getFullYear() - 5;
      const km = kmStr ? Number.parseInt(kmStr.replace(/\D/g, ''), 10) : 0;
      const fipeEstimate = estimateFallbackPrice(model || item.title, year);

      return {
        id: item.id,
        title: item.title,
        price: item.price,
        fipeEstimate,
        fipeDiff: fipeEstimate - item.price,
        thumbnailUrl: item.thumbnail ? cleanThumbUrl(item.thumbnail) : '',
        listingUrl: item.permalink ?? '',
        region: item.seller_address?.state?.name ?? filters.region,
        city: item.seller_address?.city?.name ?? '',
        km,
        brand,
        model,
        year,
        source: 'mercadolivre',
        sourceName: 'Mercado Livre',
      };
    });

    cache.set(cacheKey, { offers, fetchedAt: Date.now() });
    return offers;
  },
};