from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, ConfigDict, field_validator

from app.shipping import (
    ShippingInput,
    ShippingType,
    WeightUnit,
    calculate_shipping,
    get_exchange_rate_health,
    parse_shipping_type,
    parse_weight_unit,
)


class ShippingRequest(BaseModel):
    peso: float
    distancia: float
    tipoEnvio: ShippingType
    unidadePeso: WeightUnit = WeightUnit.G

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "peso": 3500,
                "distancia": 200,
                "tipoEnvio": "economico",
                "unidadePeso": "g",
            },
        }
    )

    @field_validator("tipoEnvio", mode="before")
    @classmethod
    def validate_shipping_type(cls, value: object) -> ShippingType:
        return parse_shipping_type(value)

    @field_validator("unidadePeso", mode="before")
    @classmethod
    def validate_weight_unit(cls, value: object) -> WeightUnit:
        return parse_weight_unit(value)


class ShippingBreakdownResponse(BaseModel):
    custoBaseBrl: float
    custoDistanciaBrl: float
    custoBaseUsd: float | None
    custoDistanciaUsd: float | None
    taxaAlfandegaUsd: float | None
    taxaCambioBrlPorUsd: float | None


class ShippingResponse(BaseModel):
    pesoKg: float
    distanciaKm: float
    tipoEnvio: ShippingType
    moeda: str
    valorTotal: float
    detalhamento: ShippingBreakdownResponse


class ExchangeRateStatus(BaseModel):
    source: str
    value: float | None
    isValid: bool
    message: str | None


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    timestamp: datetime
    exchangeRate: ExchangeRateStatus


app = FastAPI(title="API de Calculo de Frete", version="1.0.0")


@app.get("/health")
def healthcheck() -> HealthResponse:
    return HealthResponse(
        status="ok",
        service="freight-api",
        version=app.version,
        timestamp=datetime.now(timezone.utc),
        exchangeRate=ExchangeRateStatus(**get_exchange_rate_health()),
    )


@app.post("/fretes/calcular", response_model=ShippingResponse)
def calculate_freight(payload: ShippingRequest) -> ShippingResponse:
    try:
        result = calculate_shipping(
            ShippingInput(
                peso=payload.peso,
                distancia=payload.distancia,
                tipo_envio=payload.tipoEnvio,
                unidade_peso=payload.unidadePeso,
            )
        )
        return ShippingResponse(**result)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
