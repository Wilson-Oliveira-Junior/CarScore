import { OffersProvider } from './types';

// Stub pronto para futura integração oficial/parceria.
export const olxStubProvider: OffersProvider = {
  id: 'olx',
  name: 'OLX (stub)',
  async search() {
    return [];
  },
  async healthCheck() {
    return {
      healthy: false,
      note: 'Provider ainda nao integrado (stub ativo).',
    };
  },
};