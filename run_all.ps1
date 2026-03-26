<#
Run the database, backend and Flutter web app for local development.
This script opens the backend and Flutter in new PowerShell windows.

Usage: Run from repository root in an elevated PowerShell if necessary.
    .\run_all.ps1
#>

Write-Host 'Starting database (docker compose) ...'
Push-Location -Path "$PSScriptRoot\database"
docker compose up -d
Pop-Location

Write-Host 'Starting backend (npm run dev) in a new window ...'
Start-Process powershell -ArgumentList "-NoExit -Command cd '$PSScriptRoot\backend-api'; npm install; npm run dev"

Write-Host 'Starting Flutter web (in a new window) ...'
Start-Process powershell -ArgumentList "-NoExit -Command cd '$PSScriptRoot\mobile_app'; flutter pub get; flutter run -d chrome"

Write-Host 'All commands started. Check the new windows for logs.'
