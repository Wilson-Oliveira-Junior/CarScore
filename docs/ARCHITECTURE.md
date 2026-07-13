# Architecture

High-level architecture for CarScore:

- Mobile: Flutter app (Android release)
- Backend: Node.js + TypeScript + Fastify
- Database: PostgreSQL (managed)
- Integrations: FIPE, Mercado Livre (parts), other external providers
- Local fallback: versioned catalog and median calculations

Data flow:

1. Mobile sends analysis request to Fastify API
2. API queries FIPE and Parts Engine (external + cache)
3. Aggregated data and scoring engine compute final score
4. Results persisted in PostgreSQL and returned to mobile

Design notes:

- Keep external integrations resilient with timeouts and fallbacks
- Prefer read replicas and managed backups for production
- Expose health endpoints for monitoring
