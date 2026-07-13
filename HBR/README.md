# API de Calculo de Frete

Esta API recebe dados de um envio e calcula o valor do frete.

## O Que Esta API Faz

Ela recebe 4 informacoes:

- peso
- unidade do peso (`g` ou `kg`)
- distancia em km
- tipo de envio (`economico`, `expresso` ou `internacional`)

Depois disso, ela devolve o valor final do frete.

## Regras do Calculo

- Todo envio tem custo base de `10 BRL`.
- Todo envio tem custo de `0.50 BRL` por km.
- Envio `expresso` custa `50%` a mais por km.
- Envio `internacional` custa `75%` a mais por km.
- Envio `internacional` tambem tem taxa fixa de alfandega de `50 USD`.
- Envio `internacional` retorna o valor final em `USD`.
- Envio `economico` aceita no maximo `50 kg`.

Observacao:

- O peso nao influencia o valor do frete.
- O peso e usado apenas para validacao (exemplo: limite de 50 kg no envio economico).
- Essa decisao segue estritamente os requisitos fornecidos no teste.

## Regras de Validacao

- `peso` precisa ser maior que `0`.
- `distancia` precisa ser maior que `0`.
- `tipoEnvio` precisa ser `economico`, `expresso` ou `internacional`.
- Se o tipo for `economico`, o peso nao pode passar de `50 kg`.
- `unidadePeso` precisa ser `g` ou `kg`.

## Como a Unidade de Peso Funciona

- Se `unidadePeso` for `g`, o valor de `peso` e tratado como gramas.
- Se `unidadePeso` for `kg`, o valor de `peso` ja esta em quilogramas.
- Internamente, o sistema converte tudo para `kg` antes de validar e calcular.
- Exemplo: `3500 g = 3.5 kg`.

## Resumo das Formulas

- Economico (BRL):
  - `total = 10 + (distancia * 0.50)`

- Expresso (BRL):
  - `total = 10 + (distancia * 0.50 * 1.5)`

- Internacional (USD):
  - `subtotal_brl = 10 + (distancia * 0.50 * 1.75)`
  - `subtotal_usd = subtotal_brl / cambio`
  - `total_usd = subtotal_usd + 50`

## Cambio e Conversao de Moeda

- Cambio padrao: `1 USD = 5.00 BRL`.
- Esse valor foi adotado como premissa para o exercicio.
- Se necessario, ele pode ser alterado pela variavel de ambiente `USD_BRL_EXCHANGE_RATE`.
- Caso a variavel nao esteja definida, o valor padrao `5.0` e utilizado.
- Economico e expresso sao calculados e retornados em `BRL`.
- Internacional usa custos base em `BRL`, converte para `USD` e soma a alfandega (`50 USD`).
- O detalhamento internacional mostra os valores em `BRL` e `USD` para facilitar a conferencia.

## Regra de Arredondamento

- Valores monetarios e de exibicao da resposta sao arredondados para 2 casas decimais.
- Exemplo: `33.335` km vira `33.34` km na resposta.

## Rota da API

```text
POST /fretes/calcular
```

## Exemplo de Requisicao

```json
{
  "peso": 3500,
  "distancia": 200,
  "tipoEnvio": "Econômico",
  "unidadePeso": "g"
}
```

## Exemplo de Resposta Nacional

```json
{
  "pesoKg": 3.5,
  "distanciaKm": 200,
  "tipoEnvio": "economico",
  "moeda": "BRL",
  "valorTotal": 110.0,
  "detalhamento": {
    "custoBaseBrl": 10.0,
    "custoDistanciaBrl": 100.0,
    "custoBaseUsd": null,
    "custoDistanciaUsd": null,
    "taxaAlfandegaUsd": null,
    "taxaCambioBrlPorUsd": null
  }
}
```

## Exemplo de Resposta Internacional

```json
{
  "pesoKg": 100.0,
  "distanciaKm": 300.0,
  "tipoEnvio": "internacional",
  "moeda": "USD",
  "valorTotal": 104.5,
  "detalhamento": {
    "custoBaseBrl": 10.0,
    "custoDistanciaBrl": 262.5,
    "custoBaseUsd": 2.0,
    "custoDistanciaUsd": 52.5,
    "taxaAlfandegaUsd": 50.0,
    "taxaCambioBrlPorUsd": 5.0
  }
}
```

## Mensagens de Erro

- `carga tem que ter peso maior que 0 kg`
- `distancia deve ser maior que 0 km`
- `tipoEnvio deve ser economico, expresso ou internacional`
- `envio economico aceita no maximo 50 kg`
- `unidadePeso deve ser g ou kg`

## Como Rodar na Sua Maquina

Passo 1. Criar ambiente virtual:

```bash
python -m venv .venv
```

Passo 2. Ativar o ambiente virtual:

```bash
# Linux/macOS
source .venv/bin/activate

# Windows PowerShell
.venv\Scripts\Activate.ps1
```

Passo 3. Instalar dependencias:

```bash
python -m pip install -r requirements.txt
```

Passo 4. Rodar os testes:

```bash
python -m pytest -q
```

Passo 5. Iniciar a API:

```bash
python -m uvicorn app.main:app --reload
```

Passo 6. Abrir a documentacao interativa no navegador:

```text
http://127.0.0.1:8000/docs
```

## Como Rodar com Docker

Se preferir, tambem e possivel rodar com Docker.

Passo 1. Criar a imagem:

```bash
docker build -t freight-api .
```

Passo 2. Rodar o container:

```bash
docker run --rm -p 8000:8000 freight-api
```

Passo 3. Abrir a documentacao:

```text
http://127.0.0.1:8000/docs
```

## Erros Comuns

### Erro: `No module named 'fastapi'`

As dependencias nao foram instaladas no ambiente ativo.

Use:

```bash
python -m pip install -r requirements.txt
```

### Erro: `No module named 'app'`

Normalmente isso acontece quando o projeto foi executado do jeito errado.

Use estes comandos:

```bash
python -m pytest -q
python -m uvicorn app.main:app --reload
```

Nao use estes comandos:

```bash
python tests/test_shipping.py
python app/main.py
```

### Erro ao ativar o ambiente no PowerShell

Se o PowerShell bloquear a execucao do script, rode:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

Depois tente novamente:

```powershell
.venv\Scripts\Activate.ps1
```

## Assumptions

- `tipoEnvio` e normalizado (case-insensitive e sem acentos).
- Valores monetarios sao arredondados para 2 casas decimais.
- Cambio padrao `5.0` e usado quando `USD_BRL_EXCHANGE_RATE` nao estiver definida.
- O peso nao influencia no calculo, apenas na validacao.

## Retorno

Esta secao registra o retorno do feedback tecnico recebido e o que foi ajustado no projeto.

### Feedback recebido

- Faltava tipagem forte de ponta a ponta.
- `tipoEnvio` e `unidadePeso` estavam como strings soltas.
- Havia duplicacao na montagem do retorno do frete.
- O endpoint `/health` estava simples demais.
- Cobertura de casos de borda podia melhorar.
- Faltavam testes unitarios da regra sem depender do FastAPI.

### Pontos que foram mudados

- Tipagem forte adicionada na camada de dominio com `ShippingInput` e retorno tipado.
- Enums adicionados para tipo e unidade:
  - `ShippingType`: `economico`, `expresso`, `internacional`
  - `WeightUnit`: `g`, `kg`
- Validacao de entrada centralizada com parsing e normalizacao para aceitar case-insensitive e sem acento.
- Reducao de duplicacao com funcoes unicas de composicao de `detalhamento` e resposta final.
- Endpoint `/health` enriquecido com:
  - `status`
  - `service`
  - `version`
  - `timestamp`
  - `exchangeRate` (origem, valor, validade e mensagem)
- Testes ampliados com cenarios de borda:
  - limite exato de `50 kg` no economico
  - valores negativos
  - comportamento da variavel `USD_BRL_EXCHANGE_RATE` (valida, invalida e zero)
- Testes unitarios puros adicionados para validar regras de negocio sem framework web.

### Retornos que voce deve ver no Swagger

1. `GET /health`
- Deve retornar `200` com metadados da API e status da taxa de cambio.

2. `POST /fretes/calcular` com payload valido
- Deve retornar `200` com `valorTotal`, `moeda` e `detalhamento`.

3. `POST /fretes/calcular` com `unidadePeso` invalida (ex.: `lb`)
- Deve retornar `422` (erro de validacao de schema do Pydantic), com mensagem informando que a unidade deve ser `g` ou `kg`.

4. `POST /fretes/calcular` internacional com `USD_BRL_EXCHANGE_RATE=0`
- Deve retornar `400` com mensagem: `USD_BRL_EXCHANGE_RATE deve ser maior que zero`.

### Observacao importante

- A mudanca principal foi de qualidade interna e contrato da API (tipagem, validacao e robustez).
- Por isso, visualmente no Swagger a estrutura geral continua parecida, mas o comportamento de validacao e o `/health` estao mais completos.