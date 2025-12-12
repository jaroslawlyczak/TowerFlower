#!/bin/bash
# Skrypt przygotowujący projekt do push na GitHub
# Sprawdza czy nie ma hardcoded kluczy API

echo "🔍 Sprawdzanie kluczy API przed push na GitHub..."

# Sprawdź czy są jakieś hardcoded klucze API (oprócz placeholderów)
if grep -r "9b28a4b39496172d4fa569e8e11a6c1f" lib/ 2>/dev/null; then
    echo "❌ BŁĄD: Znaleziono hardcoded klucz API Aviationstack!"
    echo "   Usuń klucz z lib/services/airport_info_service.dart"
    exit 1
fi

# Sprawdź czy placeholder jest ustawiony
if ! grep -q "SET_YOUR_API_KEY_HERE" lib/services/airport_info_service.dart 2>/dev/null; then
    echo "⚠️  UWAGA: Placeholder API key nie został znaleziony"
fi

echo "✅ Sprawdzanie zakończone - gotowe do push na GitHub"
echo ""
echo "Następne kroki:"
echo "1. git add ."
echo "2. git commit -m 'Initial commit: TowerFlower'"
echo "3. git remote add origin https://github.com/TWOJA_NAZWA/TowerFlower.git"
echo "4. git push -u origin main"

