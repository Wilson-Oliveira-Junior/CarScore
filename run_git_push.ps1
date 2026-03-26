param(
    [string]$RemoteUrl = 'https://github.com/Wilson-Oliveira-Junior/CarScore.git',
    [string]$Branch = 'main',
    [string]$Message = 'chore: sync local changes'
)

Write-Host "Running git push helper"
Set-Location -Path $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error 'git not found in PATH. Please install Git and retry.'
    exit 1
}

if (-not (Test-Path .git)) {
    Write-Host 'No git repo found. Initializing new repository...'
    git init
}

$origin = git remote show origin 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Adding remote origin: $RemoteUrl"
    git remote add origin $RemoteUrl
} else {
    Write-Host 'Remote origin already exists. Setting URL to the provided remote.'
    git remote set-url origin $RemoteUrl
}

Write-Host 'Staging changes...'
git add .

Write-Host 'Creating commit (if there are staged changes)...'
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host 'No changes to commit.'
} else {
    git commit -m "$Message"
}

Write-Host "Setting branch to '$Branch' and pushing to origin..."
git branch -M $Branch

try {
    git push -u origin $Branch
} catch {
    Write-Error "Push failed: $_"
    Write-Host 'You may need to authenticate (use Git credential manager or GitHub CLI `gh auth login`).'
    exit 1
}

Write-Host 'Push completed.'