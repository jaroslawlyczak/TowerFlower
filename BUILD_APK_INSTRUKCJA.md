# Instrukcja budowania APK dla aplikacji TowerFlower

## Wymagania

1. **Flutter SDK** - zainstalowany i skonfigurowany
   - Pobierz z: https://flutter.dev/docs/get-started/install/windows
   - Dodaj Flutter do PATH środowiskowego
   - Sprawdź instalację: `flutter doctor -v`

2. **Android Studio** (opcjonalnie, ale zalecane)
   - Zainstaluj Android SDK
   - Skonfiguruj Android SDK Command-line Tools

3. **Java JDK** (wersja 11 lub nowsza)
   - Wymagane do kompilacji Android

## Metoda 1: Użycie skryptu PowerShell (zalecane)

1. Otwórz PowerShell w katalogu projektu
2. Uruchom skrypt:
```powershell
.\build_apk.ps1
```

Skrypt automatycznie:
- Sprawdzi dostępność Flutter
- Wyczyści poprzednie buildy
- Pobierze zależności
- Zbuduje APK w trybie release

## Metoda 2: Ręczne budowanie przez Flutter CLI

### Krok 1: Sprawdź konfigurację
```bash
flutter doctor -v
```

Upewnij się, że wszystkie wymagane komponenty są zainstalowane.

### Krok 2: Wyczyść projekt (opcjonalnie)
```bash
flutter clean
```

### Krok 3: Pobierz zależności
```bash
flutter pub get
```

### Krok 4: Zbuduj APK

**APK Release (do dystrybucji):**
```bash
flutter build apk --release
```

**APK Debug (do testowania):**
```bash
flutter build apk --debug
```

**APK Split (osobne APK dla różnych architektur - mniejsze pliki):**
```bash
flutter build apk --split-per-abi
```

To utworzy osobne APK dla:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM)
- `app-x86_64-release.apk` (64-bit x86)

### Krok 5: Znajdź utworzony APK

Po zakończeniu budowania, APK znajdziesz w:
```
build\app\outputs\flutter-apk\app-release.apk
```

## Instalacja APK na urządzeniu Android

### Metoda 1: Przez USB (ADB)

1. Włącz opcję "Opcje programisty" na urządzeniu Android
2. Włącz "Debugowanie USB"
3. Podłącz urządzenie do komputera przez USB
4. Zainstaluj APK:
```bash
flutter install
```
lub ręcznie:
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### Metoda 2: Przez plik

1. Skopiuj plik `app-release.apk` na urządzenie Android
2. Na urządzeniu otwórz plik APK
3. Zezwól na instalację z nieznanych źródeł (jeśli wymagane)
4. Zainstaluj aplikację

## Rozwiązywanie problemów

### Problem: "Flutter nie jest rozpoznany jako polecenie"

**Rozwiązanie:**
1. Sprawdź czy Flutter jest zainstalowany
2. Dodaj Flutter do PATH środowiskowego:
   - Otwórz "Zmienne środowiskowe" w Windows
   - Dodaj ścieżkę do `flutter\bin` do zmiennej PATH
   - Zrestartuj terminal

### Problem: "Android SDK nie znaleziony"

**Rozwiązanie:**
1. Zainstaluj Android Studio
2. Otwórz Android Studio → Settings → Appearance & Behavior → System Settings → Android SDK
3. Zainstaluj Android SDK Platform Tools
4. Ustaw zmienną środowiskową `ANDROID_HOME` wskazującą na lokalizację Android SDK

### Problem: "Gradle build failed"

**Rozwiązanie:**
1. Sprawdź czy masz zainstalowany Java JDK 11 lub nowszy
2. Ustaw zmienną środowiskową `JAVA_HOME`
3. Wyczyść projekt: `flutter clean`
4. Spróbuj ponownie: `flutter build apk --release`

### Problem: "Signing config not found"

**Rozwiązanie:**
Dla testów możesz użyć debug signing config (już skonfigurowany w projekcie).
Dla produkcji musisz skonfigurować własny klucz podpisywania w `android/app/build.gradle.kts`.

## Podpisywanie APK dla produkcji

Dla dystrybucji w Google Play Store potrzebujesz podpisanego APK:

1. Wygeneruj klucz:
```bash
keytool -genkey -v -keystore towerflower-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias towerflower
```

2. Skonfiguruj podpisywanie w `android/app/build.gradle.kts`:
```kotlin
signingConfigs {
    create("release") {
        storeFile = file("towerflower-key.jks")
        storePassword = "twoje_haslo"
        keyAlias = "towerflower"
        keyPassword = "twoje_haslo"
    }
}
```

3. Zbuduj podpisany APK:
```bash
flutter build apk --release
```

## Informacje o utworzonym APK

- **Lokalizacja:** `build\app\outputs\flutter-apk\app-release.apk`
- **Wersja:** 1.0.0+1 (z `pubspec.yaml`)
- **Package name:** `com.example.flutter_application`
- **Minimalna wersja Android:** Zgodnie z konfiguracją Flutter (domyślnie API 21)

## Dodatkowe opcje budowania

### Budowanie App Bundle (AAB) dla Google Play Store:
```bash
flutter build appbundle --release
```

### Budowanie z określoną wersją:
```bash
flutter build apk --release --build-number=2 --build-name=1.0.1
```

### Budowanie tylko dla określonej architektury:
```bash
flutter build apk --release --target-platform android-arm64
```

## Wsparcie

W razie problemów sprawdź:
- Dokumentację Flutter: https://flutter.dev/docs
- Flutter GitHub Issues: https://github.com/flutter/flutter/issues
- Stack Overflow: https://stackoverflow.com/questions/tagged/flutter





