# CarScore

Aplicativo mobile para ajudar na decisao de compra de carro usado em poucos segundos.

## Visao do produto
O usuario informa modelo, ano, preco pedido e perfil de uso.
O app retorna uma leitura objetiva de viabilidade:
- preco em relacao a referencia de mercado
- custo mensal estimado (combustivel + manutencao)
- score final de 0 a 100
- classificacao: compra saudavel / atencao / nao recomendado

## Stack escolhida
- Mobile: Flutter (Dart)
- Backend API: Node.js + TypeScript (Fastify)
- Banco de dados: PostgreSQL

## Estrutura atual do repositorio
- `backend-api`: API de calculo e endpoints
- `mobile-app`: app Flutter (a criar com comando flutter)
- `database`: ambiente local do PostgreSQL (Docker)

## Status atual
Ja feito:
- nome do projeto definido: CarScore
- backend inicial criado em TypeScript com Fastify
- endpoint de health criado
- endpoint inicial de estimativa criado
- scripts de build/dev configurados
- docker-compose do banco criado

Pendente imediato:
- instalar Flutter no ambiente
- gerar projeto mobile
- conectar app na API
- evoluir score v0.1 para score com 4 pilares

## Como rodar localmente
### 1) Requisitos
- Node.js 20+ (ja disponivel)
- npm 10+ (ja disponivel)
- Docker Desktop (para banco local)
- Flutter SDK (a instalar)

### 2) Subir o banco local
Na pasta `database`:

```bash
docker compose up -d
```

### 3) Rodar a API
Na pasta `backend-api`:

```bash
npm install
npm run dev
```

Teste rapido:

```bash
GET http://localhost:3333/health
```

### 4) Instalar Flutter (Windows)
Passo resumido:
1. baixar Flutter SDK oficial
2. extrair em `C:\src\flutter`
3. adicionar `C:\src\flutter\bin` no PATH
4. reiniciar terminal
5. executar `flutter doctor`

### 5) Criar app mobile
Na pasta `mobile-app`:

```bash
flutter create .
flutter run
```

## Regras de calculo (v0.1)
Combustivel:

```text
gasto_mensal_combustivel = (km_mes / km_por_litro) * preco_litro
```

Total mensal:

```text
custo_mensal_total = gasto_mensal_combustivel + manutencao_mensal_estimada
```

Score atual (provisorio no backend):
- calcula score com base no custo mensal total
- proxima versao usara 4 pilares: preco, combustivel, manutencao, adequacao

## Proximos passos (Sprint 1)
1. Definir contrato da API (payloads finais)
2. Implementar score em 4 pilares
3. Criar tela principal do app (busca + analise)
4. Exibir resultado com semaforo e resumo de custo

## Historico
- 2026-03-26: planejamento inicial do produto
- 2026-03-26: bootstrap tecnico inicial (backend, banco, estrutura de pastas)

## Observacoes
- O app deve exibir valores como referencia e estimativa.
- Preco, consumo e manutencao podem variar por regiao, versao e condicao do veiculo.
