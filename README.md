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
- `mobile_app`: app Flutter
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
- instalar Flutter no ambiente (você instalou e confirmou com `flutter doctor`)
- gerar projeto mobile (feito: `mobile_app` criado com `flutter create .`)
- conectar app na API (feito: ApiClient + telas de formulário/resultado)
- evoluir score v0.1 para score com 4 pilares (feito no backend v1)

Status detalhado — o que já fizemos (delta):
- Backend
	- extraída lógica de scoring para `src/score.ts` e ajustadas heurísticas/pesos
	- endpoint POST `/v1/analysis/estimate` retorna sub-scores por pilar, pesos, finalScore e label
	- persistência em PostgreSQL de análises (`analysis_history`)
	- endpoints para histórico e configuração de pesos: `/v1/analysis/history`, `/v1/config/weights`
	- testes unitários do scoring adicionados (Vitest) em `backend-api/test`
	- arquivo de documentação da API: `backend-api/API.md`

- Mobile (Flutter)
	- projeto criado em `mobile_app` (com `flutter create .`)
	- `lib/core/api_client.dart` — cliente HTTP para `http://localhost:3333`
	- `lib/features/analysis/analysis_page.dart` — formulário para envio de dados de análise
	- `lib/features/analysis/result_page.dart` — UI de resultado com barras por pilar e explicações
	- tema visual aplicado (cores/tipografia/espaçamento base) em `lib/core/app_theme.dart`
	- shell com abas em `lib/features/shell/app_shell.dart` (Início, Análise, Histórico, Config)
	- `lib/features/history/history_page.dart` conectado ao histórico real da API
	- `lib/features/settings/settings_page.dart` com sliders para ajuste real de pesos do score
	- adicionada dependência `http` em `mobile_app/pubspec.yaml`
	- teste widget básico em `mobile_app/test/` para `ResultPage`

- Conveniência / dev scripts
	- `run_all.ps1` — sobe DB (docker), backend (npm run dev) e app Flutter web (flutter run -d chrome) em novas janelas PowerShell
	- `run_git_push.ps1` — inicializa repo (se necessário), adiciona remote e faz commit+push para o GitHub remoto
	- `.gitignore` adicionado na raiz com padrões para Node/Flutter/IDE

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

Observação: o projeto Flutter já foi criado no diretório `mobile_app` neste repositório. Para rodar a aplicação web (Chrome):

```powershell
Set-Location D:\Projeto\CarScore\mobile_app
flutter pub get
flutter run -d chrome
```

Para testar o fluxo completo, certifique-se que o backend está rodando (`npm run dev`) e utilize a opção "Nova análise (formulário)" no app web.

### Testes
- Backend: na pasta `backend-api`

```powershell
npm install
npm test
```

- Mobile: na pasta `mobile_app`

```powershell
flutter test
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
2. Refinar heurísticas e pesos do scoring (já existe implementação inicial em `backend-api/src/score.ts`)
3. Melhorar UX do resultado (gráficos, explicações detalhadas, recomendações)
4. Persistência: salvar análises em banco e criar endpoints para histórico/comparação (já implementado no MVP)
5. Criar builds Android/iOS (configurar Android SDK / AVD e Visual Studio para Windows)
6. Adicionar CI: rodar `npm test` (backend) e `flutter test` (mobile) em GitHub Actions

Checklist curto (concluído / pendente):
- [x] Backend básico + endpoints
- [x] Docker compose do DB
- [x] Projeto Flutter criado
- [x] Conexão mobile ↔ backend (API client + formulário)
- [x] Score com 4 pilares e testes unitários
- [x] Tema visual aplicado nas telas novas
- [x] Persistência de análises no Postgres + histórico
- [x] Ajuste real de pesos em Configurações
- [x] Script dev `run_all.ps1` e helper `run_git_push.ps1`
- [ ] CI (GitHub Actions)
- [ ] Testes de integração end-to-end

## Historico
- 2026-03-26: planejamento inicial do produto
- 2026-03-26: bootstrap tecnico inicial (backend, banco, estrutura de pastas)

## Observacoes
- O app deve exibir valores como referencia e estimativa.
- Preco, consumo e manutencao podem variar por regiao, versao e condicao do veiculo.
