export type OfferSource = 'mercadolivre' | 'local' | 'webmotors' | 'olx';

export type MarketplaceOffer = {
  id: string;
  title: string;
  price: number;
  fipeEstimate: number;
  fipeDiff: number;
  thumbnailUrl: string;
  listingUrl: string;
  region: string;
  city: string;
  km: number;
  brand: string;
  model: string;
  year: number;
  source: OfferSource;
  sourceName: string;
  qualityScore?: number;
};

export type OffersSearchFilters = {
  region: string;
  limit: number;
  brand?: string;
  model?: string;
  minPrice?: number;
  maxPrice?: number;
  maxKm?: number;
  minYear?: number;
  providers?: OfferSource[];
};

export type OffersSearchResult = {
  items: MarketplaceOffer[];
  providersUsed: OfferSource[];
  fallbackUsed: boolean;
};

export interface OffersProvider {
  id: OfferSource;
  name: string;
  search(filters: OffersSearchFilters): Promise<MarketplaceOffer[]>;
  healthCheck?(): Promise<{ healthy: boolean; latencyMs?: number; note?: string }>;
}