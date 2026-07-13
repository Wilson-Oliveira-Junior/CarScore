# Parts Engine

Summary of the Parts Engine module (pecas).

## Purpose
Provide parts cost estimation, a parts pressure index (IPP) and a parts score to combine with the vehicle viability score.

## Inputs
- Brand, model, year, motorizacao
- Region
- Mileage
- User-provided monthly income (optional)

## Outputs
- Parts score (0-100)
- Estimated parts basket (min/median/max)
- Estimated annual maintenance cost
- IPP = cost_cesta_pecas_12m / renda_mensal_referencia

## Integration
- Primary source: Mercado Livre
- Secondary: versioned local catalog
- Endpoints provided by backend-api:
  - `GET /v1/parts/catalog`
  - `POST /v1/parts/estimate`
  - `POST /v1/analysis/estimate-with-parts`

## Readiness criteria
- Parts score available via API and app
- Historical analysis persisted with basket traceability
- Tests cover calculation, fallback and validation
