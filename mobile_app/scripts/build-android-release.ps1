param(
  [Parameter(Mandatory=$true)]
  [string]$ApiBaseUrl,

  [Parameter(Mandatory=$true)]
  [string]$BuildName,

  [Parameter(Mandatory=$true)]
  [int]$BuildNumber
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
  throw 'ApiBaseUrl nao pode ser vazio.'
}

if (-not $ApiBaseUrl.StartsWith('https://')) {
  throw 'ApiBaseUrl deve usar https para release.'
}

Write-Host '==> Limpando build anterior'
flutter clean

Write-Host '==> Baixando dependencias'
flutter pub get

Write-Host '==> Analise estatica'
flutter analyze lib

Write-Host '==> Testes'
flutter test

Write-Host '==> Gerando AAB de release'
flutter build appbundle --release --build-name=$BuildName --build-number=$BuildNumber --dart-define=API_BASE_URL=$ApiBaseUrl

$bundlePath = 'build/app/outputs/bundle/release/app-release.aab'
if (-not (Test-Path $bundlePath)) {
  throw "Bundle nao encontrado em $bundlePath"
}

Write-Host "==> Build concluido: $bundlePath"
