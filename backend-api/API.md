# CarScore API v1

Base URL local: `http://localhost:3333`

A API retorna sempre `Content-Type: application/json`.
Todos os valores monetários estão em **Reais (R$)**.

---

## GET /health

Verifica se o servidor está no ar.

**Response 200**
```json
{ "status": "ok", "service": "carscore-api" }
```

---

## POST /v1/analysis/estimate

Calcula a viabilidade de compra de um veículo com base no perfil do usuário.

**Request body**

| Campo               | Tipo   | Obrig. | Descrição                                     |
|---------------------|--------|--------|-----------------------------------------------|
| vehicleLabel        | string | sim    | Ex.: "Honda Civic". Mínimo 3 caracteres.      |
| year                | number | sim    | Ano de fabricação (1950 – ano atual + 1).      |
| askingPrice         | number | sim    | Preço pedido pelo vendedor (R$).               |
| kmPerMonth          | number | sim    | Quilometragem mensal estimada.                 |
| kmPerLiter          | number | sim    | Consumo médio do veículo (km/l).               |
| fuelPricePerLiter   | number | sim    | Preço atual do combustível (R$/l).             |
| maintenanceMonthly  | number | não    | Estimativa de manutenção/mês (R$). Padrão: 0. |

**Exemplo de request**
```json
{
  "vehicleLabel": "Honda Civic 2018",
  "year": 2018,
  "askingPrice": 72000,
  "kmPerMonth": 1200,
  "kmPerLiter": 12.5,
  "fuelPricePerLiter": 6.10,
  "maintenanceMonthly": 200
}
```

**Response 200**
```json
{
  "input": { ...campos enviados... },
  "result": {
    "fuelMonthly": 585.60,
    "monthlyTotal": 785.60,
    "pillars": {
      "priceScore": 72,
      "fuelScore": 30,
      "maintenanceScore": 80,
      "adequacyScore": 90
    },
    "weights": {
      "price": 0.4,
      "fuel": 0.25,
      "maintenance": 0.2,
      "adequacy": 0.15
    },
    "finalScore": 66,
    "label": "viavel_com_atencao"
  },
  "meta": {
    "analysisId": 1
  }
}
```

**Labels possíveis**

| label                   | finalScore | Significado para o usuário     |
|-------------------------|------------|-------------------------------|
| compra_saudavel         | 80 – 100   | Boa compra para o seu perfil. |
| viavel_com_atencao      | 60 – 79    | Viável, mas fique atento.     |
| alto_custo_para_perfil  | 40 – 59    | Custo elevado para seu uso.   |
| nao_recomendado         | 0 – 39     | Compra arriscada.             |

**Response 400**
```json
{
  "error": "invalid_payload",
  "details": { "fieldErrors": { "year": ["..."] }, "formErrors": [] }
}
```

---

## GET /v1/analysis/history

Retorna as últimas análises salvas.

**Query params**

| Param | Tipo   | Padrão | Descrição                          |
|-------|--------|--------|------------------------------------|
| limit | number | 20     | Quantidade de itens (máx. 100).    |

**Response 200**
```json
{
  "items": [
    {
      "id": 1,
      "createdAt": "2026-03-30T16:00:00.000Z",
      "vehicleLabel": "Honda Civic 2018",
      "year": 2018,
      "askingPrice": 72000,
      "finalScore": 66,
      "label": "viavel_com_atencao",
      "monthlyTotal": 785.60
    }
  ],
  "count": 1
}
```

---

## GET /v1/config/weights

Retorna os pesos atuais do score (normalizados, soma = 1).

**Response 200**
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

---

## PUT /v1/config/weights

Atualiza os pesos do score. Os valores são normalizados automaticamente (soma sempre vira 1).

**Request body**

| Campo       | Tipo   | Obrig. | Descrição                          |
|-------------|--------|--------|------------------------------------|
| price       | number | sim    | Peso do pilar de preço.            |
| fuel        | number | sim    | Peso do pilar de combustível.      |
| maintenance | number | sim    | Peso do pilar de manutenção.       |
| adequacy    | number | sim    | Peso do pilar de adequação.        |

**Exemplo de request**
```json
{ "price": 3, "fuel": 3, "maintenance": 2, "adequacy": 2 }
```

**Response 200** — pesos normalizados gravados
```json
{
  "weights": {
    "price": 0.3,
    "fuel": 0.3,
    "maintenance": 0.2,
    "adequacy": 0.2
  }
}
```

**Response 400**
```json
{ "error": "invalid_weights", "message": "The sum of all weights must be greater than zero." }
```

---

## Pilares do score — como são calculados

### Pilar 1 — Preço (price)
Compara o preço pedido com uma referência interna de depreciação.
- ≤ 80% da referência → 100 pts
- ≥ 120% da referência → 0 pts
- Entre 80% e 120% → interpolação linear

### Pilar 2 — Combustível (fuel)
Calcula gasto mensal = (km/mês ÷ km/l) × preço/l.
- ≤ R$ 80/mês → 100 pts
- ≥ R$ 800/mês → 0 pts
- Entre R$ 80 e R$ 800 → interpolação linear

### Pilar 3 — Manutenção (maintenance)
Baseado no valor de maintenanceMonthly informado pelo usuário.
- ≤ R$ 50/mês → 100 pts
- ≥ R$ 800/mês → 0 pts
- Entre R$ 50 e R$ 800 → interpolação linear

### Pilar 4 — Adequação (adequacy)
Avalia compatibilidade entre perfil de uso e veículo.
- Penaliza km/mês alto com consumo baixo.
- Penaliza consumo muito baixo (km/l < 8).

### Score final
```
finalScore = priceScore × weight.price
           + fuelScore  × weight.fuel
           + maintenanceScore × weight.maintenance
           + adequacyScore × weight.adequacy
```

---

## Fontes de dados
- Preço de referência: heurística interna de depreciação (v0.1). Fase 2 integrará FIPE.
- Consumo: informado pelo usuário. Fase 2 integrará base Inmetro/PBE.
- Manutenção: informada pelo usuário ou estimativa por faixa. Fase 2 integrará catálogo de peças.
