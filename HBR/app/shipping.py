from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from math import isfinite
import os
from typing import TypedDict
import unicodedata

BASE_COST_BRL = 10.0
COST_PER_KM_BRL = 0.5
CUSTOMS_FEE_USD = 50.0
MAX_ECONOMY_WEIGHT_KG = 50.0
DEFAULT_EXCHANGE_RATE = 5.0
CURRENCY_PRECISION = 2


class ShippingType(str, Enum):
    ECONOMICO = "economico"
    EXPRESSO = "expresso"
    INTERNACIONAL = "internacional"


class WeightUnit(str, Enum):
    G = "g"
    KG = "kg"


class Currency(str, Enum):
    BRL = "BRL"
    USD = "USD"


DISTANCE_MULTIPLIER_BY_TYPE: dict[ShippingType, float] = {
    ShippingType.ECONOMICO: 1.0,
    ShippingType.EXPRESSO: 1.5,
    ShippingType.INTERNACIONAL: 1.75,
}


class ShippingBreakdown(TypedDict):
    custoBaseBrl: float
    custoDistanciaBrl: float
    custoBaseUsd: float | None
    custoDistanciaUsd: float | None
    taxaAlfandegaUsd: float | None
    taxaCambioBrlPorUsd: float | None


class ShippingResult(TypedDict):
    pesoKg: float
    distanciaKm: float
    tipoEnvio: str
    moeda: str
    valorTotal: float
    detalhamento: ShippingBreakdown


class ExchangeRateHealth(TypedDict):
    source: str
    value: float | None
    isValid: bool
    message: str | None


@dataclass(frozen=True)
class ShippingInput:
    peso: float
    distancia: float
    tipo_envio: ShippingType
    unidade_peso: WeightUnit


def _normalize_text(value: str) -> str:
    value = value.strip().lower()
    normalized = unicodedata.normalize("NFD", value)
    return "".join(char for char in normalized if unicodedata.category(char) != "Mn")


def _ensure_positive(value: float, message: str) -> float:
    if value <= 0:
        raise ValueError(message)
    return float(value)


def _to_finite_number(value: object, field_name: str) -> float:
    try:
        number = float(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{field_name} deve ser numerico") from exc

    if not isfinite(number):
        raise ValueError(f"{field_name} deve ser numerico")

    return number


def _round_currency(value: float) -> float:
    return round(value, CURRENCY_PRECISION)


def parse_shipping_type(value: object) -> ShippingType:
    if isinstance(value, ShippingType):
        return value

    normalized_type = _normalize_text(str(value))
    try:
        return ShippingType(normalized_type)
    except ValueError as exc:
        raise ValueError("tipoEnvio deve ser economico, expresso ou internacional") from exc


def parse_weight_unit(value: object) -> WeightUnit:
    if isinstance(value, WeightUnit):
        return value

    normalized_unit = _normalize_text(str(value))
    if normalized_unit in {"g", "grama", "gramas"}:
        return WeightUnit.G
    if normalized_unit in {"kg", "quilo", "quilos", "kilograma", "kilogramas"}:
        return WeightUnit.KG
    raise ValueError("unidadePeso deve ser g ou kg")


def _to_kg(weight: float, unit: WeightUnit) -> float:
    if unit == WeightUnit.G:
        return weight / 1000.0
    return weight


def _exchange_rate() -> float:
    env_value = os.getenv("USD_BRL_EXCHANGE_RATE")
    if env_value is None:
        return DEFAULT_EXCHANGE_RATE

    try:
        value = float(env_value)
    except ValueError as exc:
        raise ValueError("USD_BRL_EXCHANGE_RATE invalida") from exc

    if value <= 0:
        raise ValueError("USD_BRL_EXCHANGE_RATE deve ser maior que zero")

    return value


def get_exchange_rate_health() -> ExchangeRateHealth:
    env_value = os.getenv("USD_BRL_EXCHANGE_RATE")
    if env_value is None:
        return {
            "source": "default",
            "value": _round_currency(DEFAULT_EXCHANGE_RATE),
            "isValid": True,
            "message": None,
        }

    try:
        value = float(env_value)
    except ValueError:
        return {
            "source": "env",
            "value": None,
            "isValid": False,
            "message": "USD_BRL_EXCHANGE_RATE invalida",
        }

    if value <= 0 or not isfinite(value):
        return {
            "source": "env",
            "value": _round_currency(value) if isfinite(value) else None,
            "isValid": False,
            "message": "USD_BRL_EXCHANGE_RATE deve ser maior que zero",
        }

    return {
        "source": "env",
        "value": _round_currency(value),
        "isValid": True,
        "message": None,
    }


def _build_breakdown(
    *,
    distance_cost_brl: float,
    exchange_rate: float | None,
    customs_fee_usd: float | None,
) -> ShippingBreakdown:
    if exchange_rate is None:
        return {
            "custoBaseBrl": _round_currency(BASE_COST_BRL),
            "custoDistanciaBrl": _round_currency(distance_cost_brl),
            "custoBaseUsd": None,
            "custoDistanciaUsd": None,
            "taxaAlfandegaUsd": None,
            "taxaCambioBrlPorUsd": None,
        }

    return {
        "custoBaseBrl": _round_currency(BASE_COST_BRL),
        "custoDistanciaBrl": _round_currency(distance_cost_brl),
        "custoBaseUsd": _round_currency(BASE_COST_BRL / exchange_rate),
        "custoDistanciaUsd": _round_currency(distance_cost_brl / exchange_rate),
        "taxaAlfandegaUsd": _round_currency(customs_fee_usd or 0.0),
        "taxaCambioBrlPorUsd": _round_currency(exchange_rate),
    }


def _build_result(
    *,
    weight_kg: float,
    distance_km: float,
    shipping_type: ShippingType,
    currency: Currency,
    total: float,
    breakdown: ShippingBreakdown,
) -> ShippingResult:
    return {
        "pesoKg": _round_currency(weight_kg),
        "distanciaKm": _round_currency(distance_km),
        "tipoEnvio": shipping_type.value,
        "moeda": currency.value,
        "valorTotal": _round_currency(total),
        "detalhamento": breakdown,
    }


def calculate_shipping(payload: ShippingInput) -> ShippingResult:
    weight = _ensure_positive(
        _to_finite_number(payload.peso, "peso"),
        "carga tem que ter peso maior que 0 kg",
    )
    distance = _ensure_positive(
        _to_finite_number(payload.distancia, "distancia"),
        "distancia deve ser maior que 0 km",
    )

    shipping_type = payload.tipo_envio
    weight_kg = _to_kg(weight, payload.unidade_peso)

    if shipping_type == ShippingType.ECONOMICO and weight_kg > MAX_ECONOMY_WEIGHT_KG:
        raise ValueError("envio economico aceita no maximo 50 kg")

    multiplier = DISTANCE_MULTIPLIER_BY_TYPE[shipping_type]
    distance_cost_brl = distance * COST_PER_KM_BRL * multiplier
    subtotal_brl = BASE_COST_BRL + distance_cost_brl

    if shipping_type != ShippingType.INTERNACIONAL:
        return _build_result(
            weight_kg=weight_kg,
            distance_km=distance,
            shipping_type=shipping_type,
            currency=Currency.BRL,
            total=subtotal_brl,
            breakdown=_build_breakdown(
                distance_cost_brl=distance_cost_brl,
                exchange_rate=None,
                customs_fee_usd=None,
            ),
        )

    rate = _exchange_rate()
    subtotal_usd = subtotal_brl / rate
    total_usd = subtotal_usd + CUSTOMS_FEE_USD
    return _build_result(
        weight_kg=weight_kg,
        distance_km=distance,
        shipping_type=shipping_type,
        currency=Currency.USD,
        total=total_usd,
        breakdown=_build_breakdown(
            distance_cost_brl=distance_cost_brl,
            exchange_rate=rate,
            customs_fee_usd=CUSTOMS_FEE_USD,
        ),
    )
