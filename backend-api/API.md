# CarScore API

This document describes the `/v1/analysis/estimate` endpoint used by the mobile app.

## POST /v1/analysis/estimate

Request body (application/json):

```json
{
  "vehicleLabel": "string",
  "year": 2020,
  "askingPrice": 35000.0,
  "kmPerMonth": 800.0,
  "kmPerLiter": 12.0,
  "fuelPricePerLiter": 5.5,
  "maintenanceMonthly": 100.0
}
```

Validation rules:
- `vehicleLabel`: string, min length 3
- `year`: integer between 1950 and currentYear+1
- numeric fields must be positive (maintenance can be 0)

Response (200):

```json
{
  "input": { /* echo of input */ },
  "result": {
    "fuelMonthly":  ... ,
    "monthlyTotal": ... ,
    "pillars": {
      "priceScore": 0-100,
      "fuelScore": 0-100,
      "maintenanceScore": 0-100,
      "adequacyScore": 0-100
    },
    "weights": {"price":0.4,"fuel":0.25,"maintenance":0.2,"adequacy":0.15},
    "finalScore": 0-100,
    "label": "compra_saudavel|viavel_com_atencao|alto_custo_para_perfil|nao_recomendado"
  }
}
```

Notes:
- The scoring is currently heuristic and intended for prototyping. We compute four pillar scores (price, fuel, maintenance, adequacy) and combine them with configurable weights. See `src/score.ts` for the exact implementation.
