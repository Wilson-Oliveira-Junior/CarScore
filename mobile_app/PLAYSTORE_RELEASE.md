# Play Store Release Guide

Este documento padroniza o processo de release Android para o CarScore.

## 1) Ambientes e URL da API

O app usa a variavel de build `API_BASE_URL`.

Ambientes sugeridos:
- staging: https://staging-api.seudominio.com
- producao: https://api.seudominio.com

Regra:
- nunca publicar build com localhost
- sempre validar endpoint de health antes de gerar o bundle

## 2) Checklist pre-release

- backend de producao online em HTTPS
- banco com backup ativo
- politica de privacidade publicada
- Data Safety revisado na Play Console
- testes backend passando
- flutter analyze sem issues
- flutter test passando

## 3) Comandos de validacao local

PowerShell:

backend:
- cd ..\backend-api
- npm run build
- npm test

mobile:
- cd ..\mobile_app
- flutter analyze lib
- flutter test

## 4) Build appbundle (AAB)

Use o script em scripts/build-android-release.ps1.

Exemplo producao:
- .\scripts\build-android-release.ps1 -ApiBaseUrl https://api.seudominio.com -BuildName 1.0.0 -BuildNumber 1

Exemplo staging:
- .\scripts\build-android-release.ps1 -ApiBaseUrl https://staging-api.seudominio.com -BuildName 1.0.0-stg -BuildNumber 1001

Saida esperada:
- build\app\outputs\bundle\release\app-release.aab

## 5) Publicacao na Play Console

- criar release na trilha interna
- subir app-release.aab
- preencher release notes
- revisar Data Safety, classificacao indicativa e politica de privacidade
- publicar primeiro na trilha fechada
- monitorar crashes e ANR antes de producao geral

## 6) Criterio de aprovacao interna

- sem falhas criticas no fluxo principal (dashboard, analise, resultado, historico)
- score combinado carro+pecas validado em dispositivo real
- confianca de cotacao de pecas exibida corretamente
- sem erros de rede sem tratamento na UX

## 7) Documentacao oficial recomendada

Fontes oficiais usadas como referencia:
- Flutter Android release: https://docs.flutter.dev/deployment/android
- Android publish overview: https://developer.android.com/studio/publish
- Play Console get started: https://developer.android.com/distribute/console
- Play Console create and set up app: https://support.google.com/googleplay/android-developer/answer/9859152
- Play Console publish your app: https://support.google.com/googleplay/android-developer/answer/6334282

Links importantes da trilha oficial Android/Play:
- Sign your app: https://developer.android.com/studio/publish/app-signing
- Version your app: https://developer.android.com/studio/publish/versioning
- Upload your bundle: https://developer.android.com/studio/publish/upload-bundle
- Target API requirement: https://support.google.com/googleplay/android-developer/answer/11926878

## 8) Tutorial rapido para publicar o CarScore

1. Validar backend e app localmente
- backend: build e testes passando
- mobile: flutter analyze e flutter test passando

2. Preparar assinatura Android
- criar upload keystore
- configurar android/key.properties
- configurar signingConfig release no Gradle

3. Gerar AAB de release
- usar scripts/build-android-release.ps1 com API_BASE_URL https

4. Criar app na Play Console
- definir idioma, nome, tipo, categoria e email de contato
- aceitar declaracoes de politica e exportacao

5. Completar requisitos de loja/compliance
- politica de privacidade publica
- Data Safety
- classificacao indicativa
- screenshots, icone e feature graphic

6. Subir em trilha interna
- enviar app-release.aab
- revisar erros/warnings de pre-review checks
- testar em dispositivos reais

7. Publicar em trilha fechada e depois producao
- usar staged rollout
- monitorar crashes, ANR e metricas de qualidade
