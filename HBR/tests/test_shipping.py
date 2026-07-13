from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_economico_valido():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 3500, "distancia": 200, "tipoEnvio": "Econômico", "unidadePeso": "g"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["moeda"] == "BRL"
    assert data["valorTotal"] == 110.0
    assert data["detalhamento"] == {
        "custoBaseBrl": 10.0,
        "custoDistanciaBrl": 100.0,
        "custoBaseUsd": None,
        "custoDistanciaUsd": None,
        "taxaAlfandegaUsd": None,
        "taxaCambioBrlPorUsd": None,
    }


def test_healthcheck_tem_metadados():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "freight-api"
    assert data["version"] == "1.0.0"
    assert data["timestamp"].endswith("Z")
    assert data["exchangeRate"] == {
        "source": "default",
        "value": 5.0,
        "isValid": True,
        "message": None,
    }


def test_expresso_valido():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 2.5, "distancia": 100, "tipoEnvio": "expresso", "unidadePeso": "kg"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["moeda"] == "BRL"
    assert data["valorTotal"] == 85.0
    assert data["detalhamento"] == {
        "custoBaseBrl": 10.0,
        "custoDistanciaBrl": 75.0,
        "custoBaseUsd": None,
        "custoDistanciaUsd": None,
        "taxaAlfandegaUsd": None,
        "taxaCambioBrlPorUsd": None,
    }


def test_internacional_valido():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 2000, "distancia": 80, "tipoEnvio": "internacional", "unidadePeso": "g"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["moeda"] == "USD"
    assert data["valorTotal"] == 66.0
    assert data["detalhamento"]["custoDistanciaBrl"] == 70.0
    assert data["detalhamento"]["custoDistanciaUsd"] == 14.0
    assert data["detalhamento"]["taxaAlfandegaUsd"] == 50.0


def test_internacional_detalhamento_explicita_brl_e_usd():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 100, "distancia": 300, "tipoEnvio": "internacional", "unidadePeso": "kg"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["valorTotal"] == 104.5
    assert data["detalhamento"] == {
        "custoBaseBrl": 10.0,
        "custoDistanciaBrl": 262.5,
        "custoBaseUsd": 2.0,
        "custoDistanciaUsd": 52.5,
        "taxaAlfandegaUsd": 50.0,
        "taxaCambioBrlPorUsd": 5.0,
    }


def test_peso_invalido():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 0, "distancia": 100, "tipoEnvio": "economico", "unidadePeso": "g"},
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "carga tem que ter peso maior que 0 kg"


def test_unidade_peso_invalida():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 1000, "distancia": 100, "tipoEnvio": "economico", "unidadePeso": "lb"},
    )
    assert response.status_code == 422


def test_tipo_envio_vazio():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 1000, "distancia": 100, "tipoEnvio": "", "unidadePeso": "g"},
    )
    assert response.status_code == 422


def test_distancia_decimal_arredonda_duas_casas():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 1000, "distancia": 33.335, "tipoEnvio": "expresso", "unidadePeso": "g"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["distanciaKm"] == 33.34
    assert data["valorTotal"] == 35.0


def test_economico_acima_do_limite():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 51, "distancia": 100, "tipoEnvio": "economico", "unidadePeso": "kg"},
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "envio economico aceita no maximo 50 kg"


def test_economico_peso_exato_limite():
    response = client.post(
        "/fretes/calcular",
        json={"peso": 50, "distancia": 100, "tipoEnvio": "economico", "unidadePeso": "kg"},
    )
    assert response.status_code == 200
    assert response.json()["valorTotal"] == 60.0


def test_valores_negativos():
    response = client.post(
        "/fretes/calcular",
        json={"peso": -1, "distancia": -100, "tipoEnvio": "economico", "unidadePeso": "kg"},
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "carga tem que ter peso maior que 0 kg"


def test_healthcheck_env_cambio_invalida(monkeypatch):
    monkeypatch.setenv("USD_BRL_EXCHANGE_RATE", "abc")
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["exchangeRate"] == {
        "source": "env",
        "value": None,
        "isValid": False,
        "message": "USD_BRL_EXCHANGE_RATE invalida",
    }


def test_internacional_com_cambio_por_env(monkeypatch):
    monkeypatch.setenv("USD_BRL_EXCHANGE_RATE", "4.25")
    response = client.post(
        "/fretes/calcular",
        json={"peso": 1000, "distancia": 100, "tipoEnvio": "internacional", "unidadePeso": "g"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["moeda"] == "USD"
    assert data["detalhamento"]["taxaCambioBrlPorUsd"] == 4.25


def test_internacional_com_cambio_zero_retorna_400(monkeypatch):
    monkeypatch.setenv("USD_BRL_EXCHANGE_RATE", "0")
    response = client.post(
        "/fretes/calcular",
        json={"peso": 1000, "distancia": 100, "tipoEnvio": "internacional", "unidadePeso": "g"},
    )
    assert response.status_code == 400
    assert response.json()["detail"] == "USD_BRL_EXCHANGE_RATE deve ser maior que zero"