# Skrypt PowerShell przygotowujący projekt do push na GitHub
# Sprawdza czy nie ma hardcoded kluczy API

Write-Host "🔍 Sprawdzanie kluczy API przed push na GitHub..." -ForegroundColor Cyan

# Sprawdź czy są jakieś hardcoded klucze API (oprócz placeholderów)
$foundKey = Select-String -Path "lib\services\airport_info_service.dart" -Pattern "9b28a4b39496172d4fa569e8e11a6c1f" -Quiet

if ($foundKey) {
    Write-Host "❌ BŁĄD: Znaleziono hardcoded klucz API Aviationstack!" -ForegroundColor Red
    Write-Host "   Usuń klucz z lib/services/airport_info_service.dart" -ForegroundColor Red
    exit 1
}

# Sprawdź czy placeholder jest ustawiony
$hasPlaceholder = Select-String -Path "lib\services\airport_info_service.dart" -Pattern "SET_YOUR_API_KEY_HERE" -Quiet

if (-not $hasPlaceholder) {
    Write-Host "⚠️  UWAGA: Placeholder API key nie został znaleziony" -ForegroundColor Yellow
}

Write-Host "✅ Sprawdzanie zakończone - gotowe do push na GitHub" -ForegroundColor Green
Write-Host ""
Write-Host "Następne kroki:" -ForegroundColor Cyan
Write-Host "1. git add ."
Write-Host "2. git commit -m 'Initial commit: TowerFlower'"
Write-Host "3. git remote add origin https://github.com/TWOJA_NAZWA/TowerFlower.git"
Write-Host "4. git push -u origin main"

