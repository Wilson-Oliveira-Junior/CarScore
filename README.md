# CarScore

Aplicativo mobile para decisao de compra de carro usado — analise rapida, comparativo FIPE e radar de ofertas regionais integrado com marketplaces.

## Visao do produto
O usuario informa modelo, ano, preco pedido e perfil de uso.
O app retorna uma leitura objetiva de viabilidade:
- preco em relacao a referencia FIPE (tabela oficial)
- custo mensal estimado (combustivel + manutencao)
- score final de 0 a 100 com classificacao visual (termometro)
- classificacao: Compra saudavel / Atencao / Nao recomendado
- radar de ofertas reais do Mercado Livre com comparativo FIPE por regiao

## Stack tecnica
- **Mobile:** Flutter (Dart 3.x)
- **Backend API:** Node.js + TypeScript 6 + Fastify (porta 3333)
- **Banco de dados:** PostgreSQL (Docker)
- **FIPE:** BrasilAPI + Parallelum/FIPE + fallback local completo (base Inmetro)
- **Marketplace:** arquitetura de providers plugáveis (Mercado Livre + Base local), pronta para Webmotors/OLX no futuro

## Estrutura do repositorio
```
backend-api/         API de calculo, FIPE e marketplace
  src/
    services/
      fipe.ts        Integracao multi-provedor: BrasilAPI + Parallelum + fallback local
      inmetro.ts     Base de consumo Inmetro (seed local)
      offers/         Providers plugáveis de ofertas, agregação, filtros e fallback
    routes/
      vehicles.ts    Endpoints FIPE: /brands /models /years /fipe-price /consumption
      offers.ts      Endpoint de ofertas: GET /v1/offers?region=&limit=
    score.ts         Motor de scoring (4 pilares: preco, combustivel, manutencao, adequacao)
    db.ts            PostgreSQL: historico + configuracao de pesos
    server.ts        Bootstrap Fastify

mobile_app/          App Flutter
  lib/
    core/
      api_client.dart     HTTP client + modelos: FipeBrand, MarketplaceOffer, etc.
      app_theme.dart      Tema visual (cores, tipografia, espacamento)
    features/
      shell/              NavigationBar com 4 abas
      dashboard/          Radar de oportunidades (mapa + hotspots + lista ML)
      analysis/           Formulario de analise + tela de resultado
      history/            Historico de analises + monitor de pecas
      settings/           Pesos do score + perfil do usuario

database/            Docker Compose do PostgreSQL local
```

## Funcionalidades implementadas

## Progresso consolidado

### Entregas realizadas nesta fase
- Refatoracao completa da UX principal do app: inicio, analise, resultado, historico e configuracoes
- Integracao FIPE com cadeia de resiliencia real: BrasilAPI -> Parallelum/FIPE -> base local
- Integracao de ofertas regionais com arquitetura de providers plugaveis
- Radar de oportunidades com comparativo FIPE, hotspots e origem do dado visivel na interface
- Busca de ofertas com filtros reais no backend e no app: regiao, marca, modelo, preco e quilometragem
- Imagens com fallback progressivo: thumbnail do anuncio -> busca externa -> icone local
- Melhorias de navegacao e pre-preenchimento entre busca FIPE, analise e resultado
- Ajustes de estabilidade do backend, cache em memoria e fallbacks operacionais

### Validado localmente
- Build do backend TypeScript concluido com sucesso
- `dart analyze lib/` sem issues
- Endpoint de busca FIPE respondendo com `source`, `sourceName` e `isFallback`
- Endpoint de ofertas respondendo com filtros por marca/modelo/preco/km
- Fallback de ofertas validado com `Toyota Corolla`, preco maximo e km maximo
- Banco PostgreSQL local iniciado via Docker Compose

### Tela Inicio — Radar de Oportunidades
- **Integracao real com Mercado Livre:** busca veiculos usados por cidade/estado via API publica MLB
- **Comparativo FIPE automatico:** cada oferta exibe preco pedido vs. estimativa FIPE + diferenca em R$
- **Hotspots no mapa:** bolhas coloridas posicionadas sobre mapa estilo cartografia (verde = abaixo da FIPE, vermelho = acima)
- **Badge de fonte:** label "Mercado Livre" (azul) ou "Base local" (cinza) em cada oferta
- **Fallback robusto:** quando ML esta fora do ar, exibe dados semeados (15 ofertas de grandes cidades)
- **Thumbnail do anuncio:** imagem real do anuncio ML; fallback via Unsplash por marca+modelo
- **Botao "Ver anuncio":** abre o link do ML diretamente (url_launcher)
- **Botao "Analisar":** atalho para busca FIPE pre-preenchida
- **Pull-to-refresh e botao de atualizar**
- **Campo de regiao** com busca ao pressionar Enter
- **Filtros reais de busca:** marca, modelo, preco maximo e quilometragem maxima

### Tela Analise — Formulario detalhado
- Banner hero com imagem do veiculo (Unsplash)
- Dica contextual sobre consulta FIPE anterior
- Campos com icones: modelo, ano, preco, km/mes, combustivel, litro preco, manutencao
- Botao adaptativo ("Gerar score detalhado" se vier de busca FIPE, "Analisar agora" senao)

### Tela Resultado — Score detalhado
- **Termometro visual** (degradê vermelho → laranja → verde) com marcador animado
- Imagem do veiculo (Unsplash por modelo)
- **Resumo financeiro:** preco pedido, ref. FIPE, km/l, tipo de combustivel, custo mensal
- Barras de progresso por pilar (preco, combustivel, manutencao, adequacao)
- Rodape com pesos usados e timestamp da analise

### Tela Busca de Veiculo (FIPE)
- Cascata: Marca → Modelo → Ano → Preco FIPE + Consumo Inmetro
- Exibe claramente a origem do valor FIPE: BrasilAPI, Parallelum/FIPE ou Base local
- Preview da imagem do veiculo ao selecionar o modelo
- Passa dados pre-preenchidos para o formulario de analise

### Tela Historico
- Aba "Carros": historico real da API (PostgreSQL)
- Aba "Pecas": monitor de pecas com botao "Adicionar" (dialog)

### Tela Configuracoes
- Sliders de pesos por pilar com explicacao de cada criterio
- Perfil do usuario: cidade, orcamento-alvo, preco do litro, preferencias (switches)

## Resiliencia das APIs

| Servico | Primario | Fallback 1 | Fallback 2 |
|---|---|---|---|
| FIPE marcas/modelos/anos/preco | BrasilAPI | Parallelum/FIPE | Base Inmetro local |
| Ofertas regionais | Provider Mercado Livre | Provider Base local | Proximos providers: Webmotors/OLX |
| Imagens de veiculos | Thumbnail ML (foto real) | Unsplash (busca por modelo) | Icone padrao |

O cache em memoria do backend (10 min TTL) reduz chamadas externas e protege contra instabilidade.

## Endpoints da API

```
GET  /health
POST /v1/analysis/estimate
GET  /v1/analysis/history?limit=
GET  /v1/config/weights
PUT  /v1/config/weights
GET  /v1/vehicles/brands
GET  /v1/vehicles/models?brandCode=
GET  /v1/vehicles/years?brandCode=&modelCode=
GET  /v1/vehicles/fipe-price?brandCode=&modelCode=&yearCode=
GET  /v1/vehicles/consumption?brand=&model=&year=
GET  /v1/offers?region=&limit=
```

## Como rodar localmente

### 1) Requisitos
- Node.js 20+ e npm 10+
- Docker Desktop
- Flutter SDK 3.x

### 2) Banco de dados
```powershell
cd database
docker compose up -d
```

### 3) Backend
```powershell
cd backend-api
npm install
npm run dev
```

### 4) App Flutter (Chrome)
```powershell
cd mobile_app
flutter pub get
flutter run -d chrome
```

### Testes
```powershell
# Backend
cd backend-api ; npm test

# Mobile
cd mobile_app ; flutter test
```

## Score — 4 pilares

| Pilar | O que avalia |
|---|---|
| Preco | Distancia do preco pedido em relacao a tabela FIPE |
| Combustivel | Custo mensal estimado (km/mes ÷ km/l × preco litro) |
| Manutencao | Custo fixo mensal com manutencao informado |
| Adequacao | Relacao custo-beneficio dado o perfil de uso |

Pesos configuráveis pelo usuario na aba Configuracoes (padrao: 25% cada).

## Historico de evolucao

- **2026-03-26:** planejamento e bootstrap tecnico (backend, banco, estrutura)
- **2026-03-30:** pipeline CI (GitHub Actions), Flutter configurado
- **2026-03-30:** redesign completo de todas as 5 telas (UX, termometro, comparativos)
- **2026-03-30:** integracao FIPE com fallback local completo (BrasilAPI + Inmetro)
- **2026-03-30:** integracao FIPE multi-provedor com Parallelum/FIPE como fonte secundaria
- **2026-03-30:** integracao Mercado Livre com fallback semeado para 15 ofertas / 10 cidades
- **2026-03-30:** mapa de hotspots com dados reais, badge de fonte, link direto ao anuncio
- **2026-03-30:** arquitetura de offers providers preparada para futuras fontes como Webmotors e OLX
- **2026-03-30:** filtros server-side e client-side para marca, modelo, preco e quilometragem

## Proximos passos

### Curto prazo
1. Adicionar selecao de providers e filtro de ano minimo na interface do dashboard
2. Criar endpoint de saude dos providers para a UI indicar quando esta em fallback
3. Melhorar deduplicacao e ranqueamento das ofertas por relevancia e qualidade do anuncio

### Medio prazo
1. Implementar novos providers reais assim que houver fonte estavel ou parceria viavel
2. Salvar buscas, filtros e alertas por usuario para monitoramento continuo de oportunidades
3. Evoluir o comparativo financeiro com custo total de posse e projecao anual

### Longo prazo
1. Transformar o CarScore em referencia de decisao de compra com monitoramento continuo do mercado
2. Adicionar experiencia mobile completa em Android/iOS com notificacoes e favoritos
3. Integrar mais fontes de dados veiculares, historico, manutencao e revenda

## Observacoes
- Valores de FIPE podem vir de BrasilAPI, Parallelum/FIPE ou base local; o app agora mostra a origem do dado ao usuario.
- Preco, consumo e manutencao podem variar por regiao, versao e condicao do veiculo.
- Android e Windows desktop requerem, respectivamente, Android SDK e Visual Studio C++ toolchain.

