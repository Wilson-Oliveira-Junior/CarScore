import { mercadoLivreProvider } from './mercadoLivre';
import { seededOffersProvider } from './seeded';
import { MarketplaceOffer, OffersProvider, OffersSearchFilters, OffersSearchResult, OfferSource } from './types';

const providers: Record<OfferSource, OffersProvider> = {
  mercadolivre: mercadoLivreProvider,
  local: seededOffersProvider,
};

function normalize(value?: string): string {
  return (value ?? '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .trim();
}

function matchesFilters(offer: MarketplaceOffer, filters: OffersSearchFilters): boolean {
  const brand = normalize(filters.brand);
  const model = normalize(filters.model);
  const region = normalize(filters.region);
  const offerBrand = normalize(offer.brand);
  const offerModel = normalize(offer.model);
  const offerTitle = normalize(offer.title);
  const offerRegion = normalize(`${offer.city} ${offer.region}`);

  if (region && !offerRegion.includes(region)) return false;
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

export function getAvailableOfferProviders(): Array<{ id: OfferSource; name: string }> {
  return Object.values(providers).map((provider) => ({ id: provider.id, name: provider.name }));
}

export async function searchOffers(filters: OffersSearchFilters): Promise<OffersSearchResult> {
  const requested: OfferSource[] = filters.providers?.length
    ? filters.providers
    : ['mercadolivre'];
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
    .sort((a, b) => a.price - b.price)
    .slice(0, filters.limit);

  return {
    items: filtered,
    providersUsed,
    fallbackUsed: providersUsed.includes('local'),
  };
}