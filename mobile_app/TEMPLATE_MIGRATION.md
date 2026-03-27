# Migracao de Template para CarScore

Este arquivo mapeia o template importado para a estrutura do CarScore no Flutter.

## Mapeamento de telas

- `initial` -> `DashboardPage` (`lib/features/dashboard/dashboard_page.dart`)
- `createExpense` -> `AnalysisPage` (`lib/features/analysis/analysis_page.dart`)
- `report` -> `ResultPage` (`lib/features/analysis/result_page.dart`)
- `searchScreen` -> `HistoryPage` (`lib/features/history/history_page.dart`)
- `settings` -> `SettingsPage` (`lib/features/settings/settings_page.dart`)

## Navegacao

- Shell com abas em `lib/features/shell/app_shell.dart`
- Ordem atual das abas:
  1. Inicio
  2. Analise
  3. Historico
  4. Config

## Contrato da API usado no app

- Endpoint: `POST /v1/analysis/estimate`
- Documento: `../backend-api/API.md`

## Checklist de migracao visual

- [x] Criar shell com barra inferior
- [x] Conectar fluxo de analise e resultado
- [ ] Aplicar cores/fonte do template no `ThemeData`
- [ ] Recriar componentes visuais do template (cards, spacing, icones)
- [ ] Implementar historico real com persistencia
- [ ] Ajustar copy final para publicacao

## Proximo passo recomendado

1. Trocar paleta e tipografia para o estilo do template.
2. Implementar historico no backend + persistencia no banco.
3. Exibir historico na aba `Historico` e permitir reabrir analises.
