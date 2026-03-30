import { estimateFallbackPrice } from '../fipe';
import { MarketplaceOffer, OffersSearchFilters, OffersProvider } from './types';

function makeSeed(
  id: string,
  title: string,
  price: number,
  brand: string,
  model: string,
  year: number,
  km: number,
  city: string,
  region: string
): MarketplaceOffer {
  const fipeEstimate = estimateFallbackPrice(model, year);
  return {
    id,
    title,
    price,
    fipeEstimate,
    fipeDiff: fipeEstimate - price,
    thumbnailUrl: '',
    listingUrl: '',
    region,
    city,
    km,
    brand,
    model,
    year,
    source: 'local',
    sourceName: 'Base local',
  };
}

export const SEEDED_OFFERS: MarketplaceOffer[] = [
  makeSeed('seed-001', 'Toyota Corolla XEi 2020', 93900, 'Toyota', 'Corolla', 2020, 52000, 'Sao Paulo - SP', 'Sao Paulo'),
  makeSeed('seed-002', 'Chevrolet Onix LT 2021', 67900, 'Chevrolet', 'Onix', 2021, 41000, 'Sao Paulo - SP', 'Sao Paulo'),
  makeSeed('seed-003', 'Hyundai HB20 Comfort 2019', 58900, 'Hyundai', 'HB20', 2019, 63000, 'Santos - SP', 'Santos'),
  makeSeed('seed-004', 'Honda Civic EX 2018', 88500, 'Honda', 'Civic', 2018, 70000, 'Curitiba - PR', 'Curitiba'),
  makeSeed('seed-005', 'Volkswagen Polo Comfortline 2021', 79900, 'Volkswagen', 'Polo', 2021, 34000, 'Belo Horizonte - MG', 'Belo Horizonte'),
  makeSeed('seed-006', 'Fiat Cronos Precision 2022', 74900, 'Fiat', 'Cronos', 2022, 28000, 'Rio de Janeiro - RJ', 'Rio de Janeiro'),
  makeSeed('seed-007', 'Jeep Renegade Sport 2020', 109900, 'Jeep', 'Renegade', 2020, 48000, 'Campinas - SP', 'Campinas'),
  makeSeed('seed-008', 'Volkswagen Gol 1.0 2018', 42900, 'Volkswagen', 'Gol', 2018, 78000, 'Porto Alegre - RS', 'Porto Alegre'),
  makeSeed('seed-009', 'Toyota Hilux SRV 2019', 188000, 'Toyota', 'Hilux', 2019, 85000, 'Goiania - GO', 'Goiania'),
  makeSeed('seed-010', 'Volkswagen T-Cross Highline 2021', 119900, 'Volkswagen', 'T-Cross', 2021, 31000, 'Brasilia - DF', 'Brasilia'),
  makeSeed('seed-011', 'Renault Kwid Zen 2022', 44900, 'Renault', 'Kwid', 2022, 22000, 'Recife - PE', 'Recife'),
  makeSeed('seed-012', 'Fiat Pulse Drive 2022', 89900, 'Fiat', 'Pulse', 2022, 19000, 'Salvador - BA', 'Salvador'),
  makeSeed('seed-013', 'Chevrolet Tracker Premier 2021', 128900, 'Chevrolet', 'Tracker', 2021, 37000, 'Sao Paulo - SP', 'Sao Paulo'),
  makeSeed('seed-014', 'Hyundai Creta Prestige 2020', 124900, 'Hyundai', 'Creta', 2020, 55000, 'Curitiba - PR', 'Curitiba'),
  makeSeed('seed-015', 'Ford Ka SE 2019', 47900, 'Ford', 'Ka', 2019, 61000, 'Fortaleza - CE', 'Fortaleza'),
];

function containsNormalized(source: string, search?: string): boolean {
  if (!search) return true;
  return source.toLowerCase().includes(search.toLowerCase().trim());
}

export const seededOffersProvider: OffersProvider = {
  id: 'local',
  name: 'Base local',
  async search(filters: OffersSearchFilters): Promise<MarketplaceOffer[]> {
    const region = filters.region.trim().toLowerCase();
    return SEEDED_OFFERS.filter((offer) => {
      const matchesRegion =
        region.length < 3 ||
        offer.region.toLowerCase().includes(region) ||
        offer.city.toLowerCase().includes(region);
      const matchesBrand = containsNormalized(offer.brand, filters.brand);
      const matchesModel = containsNormalized(offer.model, filters.model);
      return matchesRegion && matchesBrand && matchesModel;
    });
  },
};