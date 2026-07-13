from app.shipping import (
    ShippingInput,
    ShippingType,
    WeightUnit,
    calculate_shipping,
    get_exchange_rate_health,
    parse_shipping_type,
    parse_weight_unit,
)


def test_parse_shipping_type_aceita_acentuacao():
    assert parse_shipping_type("Economico") == ShippingType.ECONOMICO
    assert parse_shipping_type("Econômico") == ShippingType.ECONOMICO


def test_parse_weight_unit_aceita_alias():
    assert parse_weight_unit("gramas") == WeightUnit.G
    assert parse_weight_unit("quilo") == WeightUnit.KG


def test_calculate_shipping_economico_sem_fastapi():
    result = calculate_shipping(
        ShippingInput(
            peso=3500,
            distancia=200,
            tipo_envio=ShippingType.ECONOMICO,
            unidade_peso=WeightUnit.G,
        )
    )
    assert result["moeda"] == "BRL"
    assert result["valorTotal"] == 110.0


def test_calculate_shipping_limite_50kg_sem_fastapi():
    result = calculate_shipping(
        ShippingInput(
            peso=50,
            distancia=10,
            tipo_envio=ShippingType.ECONOMICO,
            unidade_peso=WeightUnit.KG,
        )
    )
    assert result["pesoKg"] == 50.0


def test_calculate_shipping_erro_peso_negativo_sem_fastapi():
    try:
        calculate_shipping(
            ShippingInput(
                peso=-1,
                distancia=10,
                tipo_envio=ShippingType.ECONOMICO,
                unidade_peso=WeightUnit.KG,
            )
        )
    except ValueError as exc:
        assert str(exc) == "carga tem que ter peso maior que 0 kg"
        return
    raise AssertionError("Esperava ValueError para peso negativo")


def test_get_exchange_rate_health_com_env_valida(monkeypatch):
    monkeypatch.setenv("USD_BRL_EXCHANGE_RATE", "6.75")
    assert get_exchange_rate_health() == {
        "source": "env",
        "value": 6.75,
        "isValid": True,
        "message": None,
    }


def test_get_exchange_rate_health_com_env_invalida(monkeypatch):
    monkeypatch.setenv("USD_BRL_EXCHANGE_RATE", "xpto")
    assert get_exchange_rate_health() == {
        "source": "env",
        "value": None,
        "isValid": False,
        "message": "USD_BRL_EXCHANGE_RATE invalida",
    }
