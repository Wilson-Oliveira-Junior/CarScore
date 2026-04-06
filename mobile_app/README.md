# CarScore Mobile (Flutter)

App mobile em Flutter para Android/iOS/Web.

## Configuracao de ambiente (API)

O app usa `API_BASE_URL` via `--dart-define`.

Exemplos:

```powershell
# Android emulator
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3333

# Android fisico na mesma rede
flutter run -d <device-id> --dart-define=API_BASE_URL=http://SEU_IP_LOCAL:3333

# Producao (Play Store)
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.seudominio.com
```

## Release Play Store

Use o guia detalhado e o script de automacao:
- PLAYSTORE_RELEASE.md
- scripts/build-android-release.ps1

## Notas da versao atual

- Historico de analises isolado por aparelho via clientId.
- Funcao para limpar historico do aparelho na tela de Historico.
- Monitor de pecas sem dados mock pre-carregados.
- Dashboard com correcoes de layout para evitar overflow em telas pequenas.

## Criacao do projeto Flutter
No PowerShell, dentro desta pasta, execute:

```bash
flutter create .
```

## Executar no Android (debug)
```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3333
```

## Estrutura inicial sugerida
- lib/main.dart
- lib/core/
- lib/features/analysis/
- lib/features/search/
- lib/shared/widgets/
