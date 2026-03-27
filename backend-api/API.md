# CarScore API

Base URL (local): `http://localhost:3333`

This document describes the endpoints used by the mobile app.

## GET /health

Response:

```json
{
  "status": "ok",
  "service": "carscore-api"
}
```

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
- all numeric fields must be positive (except `maintenanceMonthly` which can be zero)

Response (200):

```json
{
  "input": { /* echo of input */ },
  "result": {
    "fuelMonthly": 436.5,
    "monthlyTotal": 536.5,
    "pillars": {
      "priceScore": 80,
      "fuelScore": 50,
      "maintenanceScore": 93,
      "adequacyScore": 100
    },
    "weights": {
      "price": 0.4,
      "fuel": 0.25,
      "maintenance": 0.2,
      "adequacy": 0.15
    },
    "finalScore": 80,
    "label": "compra_saudavel"
  },
  "meta": {
    "analysisId": 12
  }
}
```

## GET /v1/analysis/history?limit=20

Returns the latest persisted analyses from PostgreSQL.

Response (200):

```json
{
  "items": [
    {
      "id": 12,
      "createdAt": "2026-03-27T00:10:11.123Z",
      "vehicleLabel": "Fusca",
      "year": 2010,
      "askingPrice": 15000,
      "monthlyTotal": 536.5,
      "finalScore": 80,
      "label": "compra_saudavel"
    }
  ],
  "count": 1
}
```

## GET /v1/config/weights

Returns current scoring weights used by `analyze(...)`.

Response (200):

```json
{
  "weights": {
    "price": 0.4,
    "fuel": 0.25,
    "maintenance": 0.2,
    "adequacy": 0.15
  }
}
```

## PUT /v1/config/weights

Updates scoring weights. Values are normalized in the backend to sum `1.0`.

Request body:

```json
{
  "price": 0.5,
  "fuel": 0.2,
  "maintenance": 0.2,
  "adequacy": 0.1
}
```

Response (200):

```json
{
  "weights": {
    "price": 0.5,
    "fuel": 0.2,
    "maintenance": 0.2,
    "adequacy": 0.1
  }
}
```

## DB bootstrap and env vars

The API initializes required tables automatically on startup (`analysis_weights` and `analysis_history`).

Default DB connection values (if env vars are not set):
- `DB_HOST=localhost`
- `DB_PORT=5432`
- `DB_USER=carscore`
- `DB_PASSWORD=carscore`
- `DB_NAME=carscore`

Optional:
- `DATABASE_URL` (takes precedence over individual vars)
