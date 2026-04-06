# CarScore

Aplicativo mobile para decisao de compra de carro usado, com score de viabilidade, comparativo FIPE e radar de ofertas.

## Objetivo desta fase

Este repositorio esta sendo preparado para publicacao do app na Google Play Store.
O foco agora e transformar o projeto em um produto publicavel, operavel em producao e em conformidade com as politicas da Play.

## Escopo MVP para Play Store

Funcionalidades que devem estar prontas para a primeira versao publica:
- Analise de viabilidade com score final (0 a 100)
- Analise de custo de pecas criticas (pressao de manutencao)
- Consulta FIPE com resiliencia de fontes
- Radar de ofertas por regiao com fallback
- Historico de analises
- Configuracao de pesos do score

## Fora de escopo do primeiro release

Itens que podem entrar apos o lancamento inicial:
- IA generativa para explicacoes avancadas de score
- Login/conta de usuario
- Alertas inteligentes por push
- Novos providers (Webmotors/OLX em producao)

## Nova frente de produto: Analise de Pecas

Problema:
- Um carro pode ter bom score geral e ainda gerar alto custo real de uso por causa de pecas caras.

Objetivo:
- Adicionar um modulo de analise de pecas para complementar o score atual de compra.

Resultado esperado para o usuario:
- Ver o risco de manutencao por pecas antes de comprar.
- Entender impacto mensal estimado de troca de itens comuns.
- Comparar dois carros tambem pelo custo de pecas.

### MVP de Pecas (primeira versao)

Entradas:
- Marca, modelo, ano, motorizacao (quando disponivel), regiao
- Quilometragem atual
- Perfil de uso (urbano, misto, rodoviario)

Saidas:
- Score de pecas (0 a 100)
- Cesta de pecas criticas com preco minimo, medio e maximo
- Custo anual estimado de manutencao por pecas de desgaste
- Alerta de pecas fora da curva (muito acima da media da categoria)

Pecas iniciais recomendadas:
- Jogo de freio
- Kit embreagem
- Amortecedores
- Pneu
- Bateria
- Bomba de combustivel
- Correia e tensor

### Modelo de calculo inicial (simples e explicavel)

- Criar indice de pressao de pecas (IPP):
	IPP = custo_cesta_pecas_12m / renda_mensal_referencia
- Converter IPP para score de pecas:
	- IPP baixo = score alto
	- IPP alto = score baixo
- Combinar com score atual do carro:
	score_final_compra = (score_carro x peso_carro) + (score_pecas x peso_pecas)

Pesos iniciais sugeridos:
- peso_carro: 0.7
- peso_pecas: 0.3

### O que precisa ser implementado

Backend:
- Novo servico de pecas em backend-api/src/services/parts/ (concluido - v1 local)
- Tabela de referencia local de precos por peca/marca/modelo (concluido - seed local v1)
- Endpoint para cotacao de pecas e endpoint para score de pecas (concluido)
- Persistir historico da analise de pecas junto da analise de carro (concluido)

Mobile:
- Nova secao na tela de resultado com score de pecas (concluido)
- Nova tela de detalhe de pecas com comparativo por faixa de preco (concluido)
- Opcao de incluir renda mensal para personalizar risco (concluido)
- Atualizar historico para exibir score combinado (concluido)
- Indicador de confianca da cotacao de pecas (concluido)

Dados e resiliencia:
- Fonte primaria: provedor externo (Mercado Livre)
- Fonte secundaria: base local versionada no repositorio
- Fallback: mediana por categoria de veiculo

### Endpoints novos propostos

- GET /v1/parts/catalog?brand=&model=&year=
- POST /v1/parts/estimate
- POST /v1/analysis/estimate-with-parts

Status atual dos endpoints de pecas:
- GET /v1/parts/catalog (implementado)
- POST /v1/parts/estimate (implementado)
- POST /v1/analysis/estimate-with-parts (implementado)
- Integracao externa de precos com Mercado Livre + fallback local (implementado)
- Protecao de IPP com renda de referencia por regiao e minimo de seguranca (implementado)

### Criterio de pronto do modulo de pecas

- Score de pecas disponivel na API e no app
- Resultado final mostrando score carro, score pecas e score combinado
- Historico salvo com rastreabilidade da cesta usada no calculo
- Testes cobrindo calculo, fallback e validacao de payload

## Arquitetura alvo para producao

- Mobile: Flutter (Android release)
- Backend: Node.js + TypeScript + Fastify
- Banco: PostgreSQL gerenciado
- Integracoes externas: BrasilAPI, Parallelum/FIPE, Mercado Livre

Importante:
- O app publicado nao pode depender de localhost.
- Toda API deve estar hospedada com HTTPS valido.
- Fallbacks devem continuar ativos para degradacao controlada.

## Plano de publicacao na Play Store

## Mudancas obrigatorias no projeto para Play Store

Aplicativo Android:
- Remover qualquer dependencia de localhost no app
- Implementar configuracao de ambientes (dev, staging, prod)
- Garantir assinatura de release e controle de versao Android
- Revisar permissoes e manter apenas o necessario

Backend e infraestrutura:
- Publicar API em dominio HTTPS estavel
- Configurar banco gerenciado com backup e restauracao testada
- Adicionar rate limit, timeout e observabilidade minima
- Definir estrategia de segredo e rotacao de chaves

Qualidade:
- Suite minima de testes de regressao para API critica
- Teste em Android fisico para fluxo completo
- Plano de degradacao quando FIPE/ofertas estiverem indisponiveis

Play Console e compliance:
- Politica de privacidade publica e consistente com o app
- Preenchimento correto de Data Safety
- Classificacao indicativa e conteudo da ficha da loja
- Materiais obrigatorios: icone, screenshots e feature graphic

Operacao apos lancamento:
- Definir monitoramento de erros e tempo de resposta
- Definir canal de suporte e SLA basico de resposta
- Planejar trilha interna e depois trilha de producao

## Fase 1 - Produto e compliance

Checklist:
- Definir versao de release (MVP fechado)
- Revisar textos de loja (titulo, descricao curta, descricao completa)
- Criar politica de privacidade publica (URL)
- Preparar formulario Data Safety da Play Console
- Validar tratamento de dados pessoais (coleta, uso, retencao)
- Definir email de suporte e canal de contato

Criterio de saida:
- Documentacao legal pronta e requisitos de loja definidos.

## Fase 2 - Backend em producao

Checklist:
- Subir backend em ambiente publico (staging e prod)
- Provisionar PostgreSQL gerenciado com backup
- Configurar variaveis de ambiente seguras
- Habilitar CORS para dominios autorizados
- Adicionar rate limiting e timeouts
- Configurar logs estruturados e monitoramento basico
- Publicar endpoint de health para monitoracao

Criterio de saida:
- API estavel em HTTPS com observabilidade minima.

## Fase 3 - App Flutter para release Android

Checklist:
- Criar configuracao de ambientes (dev, staging, prod)
- Apontar app para API de producao (sem localhost)
- Revisar permissoes Android (somente necessarias)
- Configurar assinatura com keystore
- Gerar app bundle (.aab)
- Ajustar versionCode e versionName
- Validar integracoes externas em dispositivo real

Criterio de saida:
- Build release assinado, instalavel e estavel.

## Fase 4 - Qualidade pre-publicacao

Checklist:
- Teste funcional ponta a ponta em Android real
- Teste de degradacao (FIPE/offers indisponiveis)
- Teste de latencia e timeout de API
- Revisao de UX para estados de erro e vazio
- Revisao de crash logs

Criterio de saida:
- Sem bloqueadores para submissao.

## Fase 5 - Play Console e lancamento

Checklist:
- Criar app na Play Console
- Enviar .aab assinado
- Preencher Data Safety e classificacao indicativa
- Subir icone, feature graphic e screenshots
- Publicar em trilha interna/fechada primeiro
- Coletar feedback e corrigir antes da producao

Criterio de saida:
- App aprovado e publicado na trilha desejada.

## Status atual resumido

Ja existe base funcional forte para o MVP:
- Backend com endpoints de analise, FIPE, ofertas e configuracoes
- App Flutter com dashboard, analise, resultado, historico e settings
- Fallbacks para fontes externas e cache de resiliencia

Principais gaps para publicacao:
- Formalizacao de compliance (politica e Data Safety)
- Infraestrutura de producao consolidada
- Pipeline de release Android (assinatura e AAB)
- Bateria de testes em dispositivo real com foco em falhas externas
- Checklist final de ambientes (staging/prod) e build release com `--dart-define` (guia e script prontos)

## Comandos uteis (ambiente local)

Banco:

```powershell
cd database
docker compose up -d
```

Backend:

```powershell
cd backend-api
npm install
npm run dev
```

Mobile:

```powershell
cd mobile_app
flutter pub get
flutter run -d android
```

Release Play Store (guia e automacao):
- mobile_app/PLAYSTORE_RELEASE.md
- mobile_app/scripts/build-android-release.ps1

## Limpeza basica concluida

- Removido arquivo legado sem uso da UI mobile (`features/home/home_page.dart`).
- Historico de analises agora pode ser filtrado por identificador do dispositivo (clientId), evitando mistura de registros de testes antigos.
- Aba de pecas no historico nao inicia mais com dado mock fixo; passa a listar apenas itens adicionados pelo usuario no aparelho.
- Cards do dashboard ajustados para telas menores para evitar overflow horizontal.

## Estado atual do produto

- Dados de ofertas podem vir de fonte externa (Mercado Livre) com fallback controlado para base local quando necessario.
- Analise com score de carro + score de pecas + score combinado ativa no backend e no mobile.
- Build debug Android validado e gerado localmente em `mobile_app/build/app/outputs/flutter-apk/app-debug.apk`.

## Proximo passo recomendado

- Publicar backend em HTTPS (staging/prod) e trocar `API_BASE_URL` de release para endpoint publico.
- Gerar AAB assinado para submissao na Play Console.
