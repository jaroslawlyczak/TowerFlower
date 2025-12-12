# Instrukcja przygotowania repozytorium GitHub

## Krok 1: Usunięcie kluczy API przed push

Przed wypchnięciem kodu na GitHub upewnij się, że:

1. **Klucz API Aviationstack** został usunięty z `lib/services/airport_info_service.dart`
   - Plik został już zaktualizowany - klucz został usunięty
   - Ustaw klucz przez metodę `setApiKey()` lub zmienną środowiskową

2. **Firebase API keys** w `lib/firebase_options.dart`
   - Te klucze są publiczne (client-side) i można je commitować
   - Jeśli chcesz je ukryć, użyj zmiennych środowiskowych

3. **Google Services JSON** (`android/app/google-services.json`)
   - Ten plik jest już w .gitignore
   - Nie będzie commitowany

## Krok 2: Utworzenie repozytorium na GitHub

```bash
# 1. Utwórz nowe repozytorium na GitHub o nazwie "TowerFlower"
#    (przez interfejs webowy GitHub)

# 2. W katalogu projektu wykonaj:
git init
git add .
git commit -m "Initial commit: TowerFlower flight tracking app"

# 3. Dodaj remote i wypchnij:
git remote add origin https://github.com/TWOJA_NAZWA_UZYTKOWNIKA/TowerFlower.git
git branch -M main
git push -u origin main
```

## Krok 3: Konfiguracja po sklonowaniu

Po sklonowaniu repozytorium:

1. **Przywróć klucze API:**
   - Ustaw klucz Aviationstack przez `AirportInfoService().setApiKey('TWÓJ_KLUCZ')`
   - Lub użyj zmiennych środowiskowych z pakietem `flutter_dotenv`

2. **Wygeneruj `firebase_options.dart`:**
   ```bash
   flutterfire configure
   ```

3. **Dodaj `google-services.json`:**
   - Pobierz z Firebase Console
   - Umieść w `android/app/google-services.json`

## Uwagi

- Plik `.gitignore` został zaktualizowany, aby ignorować pliki z kluczami API
- Testy automatyczne zostały dodane w katalogu `test/`
- Upewnij się, że nie commitowałeś żadnych kluczy API przed push

