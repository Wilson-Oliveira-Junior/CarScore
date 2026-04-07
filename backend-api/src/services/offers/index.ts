import { mercadoLivreProvider } from './mercadoLivre';
import { seededOffersProvider } from './seeded';
import { webmotorsStubProvider } from './webmotorsStub';
import { olxStubProvider } from './olxStub';
import { MarketplaceOffer, OffersProvider, OffersSearchFilters, OffersSearchResult, OfferSource } from './types';

const providers: Record<OfferSource, OffersProvider> = {
  mercadolivre: mercadoLivreProvider,
  local: seededOffersProvider,
  webmotors: webmotorsStubProvider,
  olx: olxStubProvider,
};

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

function matchesFilters(offer: MarketplaceOffer, filters: OffersSearchFilters): boolean {
  const brand = normalize(filters.brand);
  const model = normalize(filters.model);
  const region = normalize(filters.region);
  const offerBrand = normalize(offer.brand);
  const offerModel = normalize(offer.model);
  const offerTitle = normalize(offer.title);
  const offerRegion = normalize(`${offer.city} ${offer.region}`);

  if (region && !isGenericRegion(region) && !offerRegion.includes(region)) return false;
  if (brand && !(offerBrand.includes(brand) || offerTitle.includes(brand))) return false;
  if (model && !(offerModel.includes(model) || offerTitle.includes(model))) return false;
  if (filters.minPrice != null && offer.price < filters.minPrice) return false;
  if (filters.maxPrice != null && offer.price > filters.maxPrice) return false;
  if (filters.maxKm != null && offer.km > 0 && offer.km > filters.maxKm) return false;
  if (filters.minYear != null && offer.year > 0 && offer.year < filters.minYear) return false;
  return true;
}

function dedupeOffers(items: MarketplaceOffer[]): MarketplaceOffer[] {
  const seen = new Set<string>();
  const result: MarketplaceOffer[] = [];

  for (const item of items) {
    const key = [normalize(item.title), Math.round(item.price), normalize(item.city), item.year].join('|');
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }

  return result;
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function computeQualityScore(offer: MarketplaceOffer): number {
  const bargainScore = clamp((offer.fipeDiff / Math.max(1, offer.fipeEstimate)) * 100, -20, 20) + 50;
  const kmPenalty = offer.km > 0 ? clamp((offer.km - 50000) / 2500, 0, 20) : 8;
  const yearBonus = offer.year > 0 ? clamp((offer.year - 2016) * 1.8, 0, 16) : 0;
  const imageBonus = offer.thumbnailUrl.length > 0 ? 5 : 0;
  const linkBonus = offer.listingUrl.length > 0 ? 4 : 0;
  const sourceBonus = offer.source === 'mercadolivre' ? 5 : 0;

  const raw = bargainScore - kmPenalty + yearBonus + imageBonus + linkBonus + sourceBonus;
  return clamp(Math.round(raw), 0, 100);
}

export function normalizeProviderList(raw?: OfferSource[]): OfferSource[] {
  if (!raw || raw.length === 0) return ['mercadolivre'];
  const valid = raw.filter((item): item is OfferSource => item in providers);
  return valid.length > 0 ? Array.from(new Set(valid)) : ['mercadolivre'];
}

export function getAvailableOfferProviders(): Array<{ id: OfferSource; name: string }> {
  return Object.values(providers).map((provider) => ({ id: provider.id, name: provider.name }));
}

export async function getOfferProvidersHealth() {
  const checks = await Promise.all(
    Object.values(providers).map(async (provider) => {
      const started = Date.now();
      const status = provider.healthCheck
        ? await provider.healthCheck()
        : { healthy: false, note: 'no_health_check_implemented' };
      return {
        id: provider.id,
        name: provider.name,
        healthy: status.healthy,
        latencyMs: status.latencyMs ?? Date.now() - started,
        note: status.note ?? null,
      };
    })
  );

  return checks;
}

export async function searchOffers(filters: OffersSearchFilters): Promise<OffersSearchResult> {
  const requested = normalizeProviderList(filters.providers);
  const activeProviders = requested.map((id) => providers[id]).filter(Boolean);
  const providersUsed: OfferSource[] = [];
  const collected: MarketplaceOffer[] = [];

  for (const provider of activeProviders) {
    try {
      const items = await provider.search(filters);
      providersUsed.push(provider.id);
      collected.push(...items);
    } catch {
      if (provider.id !== 'local') {
        continue;
      }
    }
  }

  if (!providersUsed.includes('local') && collected.length === 0) {
    const fallback = await providers.local.search(filters);
    providersUsed.push('local');
    collected.push(...fallback);
  }

  const filtered = dedupeOffers(collected)
    .filter((item) => matchesFilters(item, filters))
    .map((item) => ({ ...item, qualityScore: computeQualityScore(item) }))
    .sort((a, b) => {
      const qualityDelta = (b.qualityScore ?? 0) - (a.qualityScore ?? 0);
      if (qualityDelta !== 0) return qualityDelta;
      return a.price - b.price;
    })
    .slice(0, filters.limit);

  return {
    items: filtered,
    providersUsed,
    fallbackUsed: providersUsed.includes('local'),
  };
}