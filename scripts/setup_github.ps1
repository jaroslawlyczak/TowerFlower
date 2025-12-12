# Skrypt PowerShell do inicjalizacji repozytorium Git i push na GitHub
# Użycie: .\scripts\setup_github.ps1

param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername = "",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "TowerFlower"
)

Write-Host "🚀 Przygotowanie repozytorium GitHub dla TowerFlower" -ForegroundColor Cyan
Write-Host ""

# Sprawdź czy git jest zainstalowany
try {
    $gitVersion = git --version
    Write-Host "✅ Git znaleziony: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Git nie jest zainstalowany. Zainstaluj Git: https://git-scm.com/downloads" -ForegroundColor Red
    exit 1
}

# Sprawdź czy nie ma już repozytorium Git
if (Test-Path ".git") {
    Write-Host "⚠️  Repozytorium Git już istnieje" -ForegroundColor Yellow
    $continue = Read-Host "Czy chcesz kontynuować? (t/n)"
    if ($continue -ne "t") {
        exit 0
    }
} else {
    Write-Host "📦 Inicjalizacja repozytorium Git..." -ForegroundColor Cyan
    git init
    Write-Host "✅ Repozytorium zainicjalizowane" -ForegroundColor Green
}

# Sprawdź klucze API
Write-Host ""
Write-Host "🔍 Sprawdzanie kluczy API..." -ForegroundColor Cyan
$foundKey = Select-String -Path "lib\services\airport_info_service.dart" -Pattern "9b28a4b39496172d4fa569e8e11a6c1f" -Quiet

if ($foundKey) {
    Write-Host "❌ BŁĄD: Znaleziono hardcoded klucz API Aviationstack!" -ForegroundColor Red
    Write-Host "   Usuń klucz z lib/services/airport_info_service.dart przed kontynuowaniem" -ForegroundColor Red
    exit 1
}

$hasPlaceholder = Select-String -Path "lib\services\airport_info_service.dart" -Pattern "SET_YOUR_API_KEY_HERE" -Quiet

if (-not $hasPlaceholder) {
    Write-Host "⚠️  UWAGA: Placeholder API key nie został znaleziony" -ForegroundColor Yellow
} else {
    Write-Host "✅ Klucz API został zastąpiony placeholderem" -ForegroundColor Green
}

# Dodaj wszystkie pliki
Write-Host ""
Write-Host "📝 Dodawanie plików do Git..." -ForegroundColor Cyan
git add .

# Sprawdź status
Write-Host ""
Write-Host "📊 Status repozytorium:" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "💾 Utworzenie commita..." -ForegroundColor Cyan
$commitMessage = "Initial commit: TowerFlower flight tracking app"
git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Commit utworzony pomyślnie" -ForegroundColor Green
} else {
    Write-Host "⚠️  Brak zmian do commitowania lub błąd" -ForegroundColor Yellow
}

# Konfiguracja remote
Write-Host ""
if ($GitHubUsername -eq "") {
    $GitHubUsername = Read-Host "Podaj swoją nazwę użytkownika GitHub"
}

$remoteUrl = "https://github.com/$GitHubUsername/$RepoName.git"

Write-Host ""
Write-Host "🔗 Konfiguracja remote repository..." -ForegroundColor Cyan
Write-Host "   URL: $remoteUrl" -ForegroundColor Gray

# Sprawdź czy remote już istnieje
$existingRemote = git remote get-url origin 2>$null
if ($existingRemote) {
    Write-Host "⚠️  Remote 'origin' już istnieje: $existingRemote" -ForegroundColor Yellow
    $changeRemote = Read-Host "Czy chcesz zmienić remote? (t/n)"
    if ($changeRemote -eq "t") {
        git remote set-url origin $remoteUrl
        Write-Host "✅ Remote zaktualizowany" -ForegroundColor Green
    }
} else {
    git remote add origin $remoteUrl
    Write-Host "✅ Remote dodany" -ForegroundColor Green
}

# Ustawienie brancha na main
Write-Host ""
Write-Host "🌿 Konfiguracja brancha..." -ForegroundColor Cyan
git branch -M main

Write-Host ""
Write-Host "✅ Gotowe!" -ForegroundColor Green
Write-Host ""
Write-Host "📤 Następny krok - wypchnij kod na GitHub:" -ForegroundColor Cyan
Write-Host "   git push -u origin main" -ForegroundColor White
Write-Host ""
Write-Host "💡 Uwaga: Jeśli repozytorium nie istnieje na GitHub, utwórz je najpierw:" -ForegroundColor Yellow
Write-Host "   1. Przejdź na https://github.com/new" -ForegroundColor Gray
Write-Host "   2. Utwórz nowe repozytorium o nazwie: $RepoName" -ForegroundColor Gray
Write-Host "   3. NIE inicjalizuj README, .gitignore ani licencji" -ForegroundColor Gray
Write-Host "   4. Następnie uruchom: git push -u origin main" -ForegroundColor Gray

