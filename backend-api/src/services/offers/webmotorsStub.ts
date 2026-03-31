import { OffersProvider } from './types';

// Stub pronto para futura integração oficial/parceria.
export const webmotorsStubProvider: OffersProvider = {
  id: 'webmotors',
  name: 'Webmotors (stub)',
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