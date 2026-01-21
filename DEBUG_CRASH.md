# Rozwiązywanie problemu z crash'em aplikacji

## Wprowadzone poprawki

1. **Dodano obsługę błędów przy inicjalizacji Firebase** - aplikacja nie crashuje jeśli Firebase nie może się zainicjalizować
2. **Bezpieczne logowanie Analytics** - błędy Analytics nie powodują crash'a aplikacji
3. **Lepsza obsługa błędów w getAirports()** - aplikacja używa domyślnej listy lotnisk jeśli Firebase nie działa

## Nowy APK

Zbudowano nowy APK z poprawkami:
- Lokalizacja: `build\app\outputs\flutter-apk\app-release.apk`
- Rozmiar: 61.02 MB

## Sprawdzanie logów błędów

Jeśli aplikacja nadal się crashuje, możesz sprawdzić logi:

### Metoda 1: Przez Flutter (jeśli masz urządzenie podłączone)

```bash
flutter logs
```

### Metoda 2: Przez ADB logcat

1. Podłącz urządzenie Android przez USB
2. Włącz "Debugowanie USB" w ustawieniach deweloperskich
3. Uruchom:

```bash
# Windows PowerShell
$env:ANDROID_HOME = "C:\Users\jarek\AppData\Local\Android\sdk"
& "$env:ANDROID_HOME\platform-tools\adb.exe" logcat | Select-String -Pattern "flutter|AndroidRuntime|FATAL|Exception"
```

Lub prościej:
```bash
adb logcat | findstr /i "flutter AndroidRuntime FATAL Exception"
```

### Metoda 3: Sprawdź logi w Android Studio

1. Otwórz Android Studio
2. Podłącz urządzenie
3. Otwórz zakładkę "Logcat"
4. Filtruj po: `flutter`, `AndroidRuntime`, `FATAL`

## Możliwe przyczyny crash'a

### 1. Problem z Firebase

**Objawy:**
- Aplikacja crashuje zaraz po uruchomieniu
- W logach widzisz błędy związane z Firebase

**Rozwiązanie:**
- Sprawdź czy plik `android/app/google-services.json` jest poprawny
- Sprawdź czy Firebase jest poprawnie skonfigurowany w konsoli Firebase
- Upewnij się, że package name w `google-services.json` odpowiada `applicationId` w `build.gradle.kts`

### 2. Brak uprawnień internetowych

**Objawy:**
- Aplikacja crashuje przy próbie pobrania danych

**Rozwiązanie:**
- Sprawdź czy urządzenie ma dostęp do internetu
- Sprawdź czy uprawnienie `INTERNET` jest w `AndroidManifest.xml` (już jest)

### 3. Problem z dostępem do zasobów

**Objawy:**
- Błędy związane z `assets/logo.png`

**Rozwiązanie:**
- Sprawdź czy plik `assets/logo.png` istnieje
- Sprawdź czy jest zdefiniowany w `pubspec.yaml`

### 4. Problem z minSdkVersion

**Objawy:**
- Błąd o niekompatybilnej wersji SDK

**Rozwiązanie:**
- Zaktualizowano już `minSdk` do 23 w `build.gradle.kts`
- Upewnij się, że urządzenie ma Android 6.0 (API 23) lub nowszy

## Testowanie w trybie debug

Aby uzyskać więcej informacji o błędach, zbuduj APK w trybie debug:

```bash
flutter build apk --debug
```

Lub uruchom aplikację bezpośrednio z Flutter:

```bash
flutter run --release
```

## Sprawdzanie konkretnych błędów

### Jeśli widzisz błąd związany z Firebase:

1. Sprawdź konfigurację Firebase:
   - Otwórz konsolę Firebase: https://console.firebase.google.com/
   - Sprawdź czy projekt `towerflower-65b92` istnieje
   - Sprawdź czy aplikacja Android jest dodana do projektu

2. Sprawdź `google-services.json`:
   - Plik powinien być w `android/app/google-services.json`
   - Package name powinien być: `com.example.flutter_application`

### Jeśli widzisz błąd związany z zasobami:

1. Sprawdź `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/logo.png
    - assets/app_icon.png
```

2. Sprawdź czy pliki istnieją w katalogu `assets/`

## Kontakt i wsparcie

Jeśli aplikacja nadal się crashuje po zastosowaniu poprawek:

1. Zbierz logi błędów (patrz wyżej)
2. Sprawdź wersję Android na urządzeniu
3. Sprawdź czy urządzenie ma dostęp do internetu
4. Spróbuj uruchomić aplikację w trybie debug dla więcej informacji

## Dodatkowe kroki debugowania

### Włącz verbose logging w kodzie

Możesz dodać więcej logów w `main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('=== Starting TowerFlower ===');
  
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  debugPrint('Running app...');
  runApp(TowerFlowerApp());
}
```

### Sprawdź czy Firebase jest dostępny

Możesz dodać sprawdzenie w `SplashScreen`:

```dart
Future<void> _loadAirports() async {
  try {
    debugPrint('Loading airports...');
    await loadAirports();
    debugPrint('Airports loaded successfully');
  } catch (e) {
    debugPrint('Error loading airports: $e');
    // Aplikacja użyje domyślnej listy lotnisk
  }
}
```





