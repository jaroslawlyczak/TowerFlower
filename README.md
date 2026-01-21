# TowerFlower

Aplikacja Flutter do śledzenia lotów i zarządzania informacjami lotniskowymi.

## Funkcjonalności

- 🗺️ **Interaktywna mapa lotów** - wizualizacja samolotów w czasie rzeczywistym z wieloma warstwami mapowymi (OSM Standard, OSM HOT, Topo)
- ✈️ **Lista lotów** - przeglądanie lotów w okolicy wybranego lotniska
- 🔴 **Live Tracking** - śledzenie wybranego samolotu na żywo z postępującą trasą i automatycznym centrowaniem mapy
- 📸 **Galeria zdjęć** - przeglądanie i udostępnianie zdjęć samolotów z systemem polubień
- 🎧 **Strumienie audio** - odtwarzanie transmisji z wież kontrolnych lotnisk
- 🏢 **Zarządzanie lotniskami** - wybór i zarządzanie ulubionymi lotniskami
- 👤 **Uwierzytelnianie** - logowanie i rejestracja użytkowników (opcjonalne, wymaga Firebase)
- ⚙️ **Ustawienia** - konfiguracja preferencji użytkownika

## Wymagania

- Flutter SDK ^3.7.0
- Dart SDK
- Firebase (opcjonalnie, dla funkcji społecznościowych - aplikacja może działać bez Firebase)
- Klucz API Aviationstack (opcjonalnie, dla szczegółowych informacji o przylotach i odlotach)

## Instalacja

1. Sklonuj repozytorium:
```bash
git clone https://github.com/TWOJA_NAZWA/TowerFlower.git
cd TowerFlower
```

2. Zainstaluj zależności:
```bash
flutter pub get
```

3. Skonfiguruj Firebase (opcjonalnie, ale zalecane):
```bash
flutterfire configure
```
Lub ręcznie skonfiguruj pliki `google-services.json` (Android) i `GoogleService-Info.plist` (iOS).

**Uwaga:** Aplikacja może działać bez Firebase, ale z ograniczoną funkcjonalnością (brak uwierzytelniania, synchronizacji danych, przechowywania zdjęć w chmurze).

4. Dodaj klucz API Aviationstack (opcjonalnie, dla szczegółowych informacji o przylotach i odlotach):
   - Utwórz plik `.env` w katalogu głównym
   - Dodaj: `AVIATIONSTACK_API_KEY=twój_klucz`
   - Lub ustaw klucz przez interfejs aplikacji w ekranie ustawień
   - Klucz może być przechowywany lokalnie (SharedPreferences) lub w Firebase dla zalogowanych użytkowników

5. Uruchom aplikację:
```bash
flutter run
```

## Konfiguracja API

### OpenSky Network
Aplikacja używa darmowego API OpenSky Network do śledzenia lotów w czasie rzeczywistym. Nie wymaga klucza API.

**Funkcjonalności:**
- Śledzenie lotów w czasie rzeczywistym na interaktywnej mapie
- Live tracking wybranego samolotu z postępującą trasą
- Pobieranie historycznych tras lotów
- Dane o pozycji, prędkości, wysokości i kierunku lotu

**Ograniczenia:**
- Rate limiting: ~10 zapytań na sekundę
- Dane dostępne tylko dla lotów w zasięgu stacji naziemnych OpenSky Network

### Aviationstack API
Aplikacja używa Aviationstack API do pobierania szczegółowych informacji o przylotach i odlotach dla wybranych lotnisk.

**Funkcjonalności:**
- Przyloty i odloty dla danego lotniska
- Szczegółowe informacje o lotach (numer lotu, linia lotnicza, bramka, terminal)
- Status lotu (On Time, Delayed, Landed, Departed)
- Filtrowanie lotów według czasu (domyślnie ±1 godzina)

**Wymagania:**
- Wymaga klucza API z [Aviationstack](https://aviationstack.com/) (darmowy plan dostępny)
- Klucz może być przechowywany lokalnie lub w Firebase dla zalogowanych użytkowników

**Konfiguracja:**
- Ustaw klucz przez zmienną środowiskową `.env`: `AVIATIONSTACK_API_KEY=twój_klucz`
- Lub użyj metody `AirportInfoService().setApiKey('twój_klucz')`
- Lub ustaw klucz przez interfejs aplikacji w ekranie ustawień

## Testy

Uruchom testy automatyczne:
```bash
flutter test
```

## Struktura projektu

```
lib/
├── models/              # Modele danych (Flight, Airport, AircraftPhoto, etc.)
├── screens/             # Ekrany aplikacji (MapScreen, FlightsBoardScreen, etc.)
├── services/            # Serwisy API i Firebase (OpenSkyService, FirebaseService, etc.)
├── widgets/             # Komponenty UI wielokrotnego użytku
├── firebase_options.dart # Konfiguracja Firebase
└── main.dart            # Punkt wejścia aplikacji
```

## Platformy

Aplikacja obsługuje następujące platformy:
- **Android** - aplikacja natywna


## Licencja

Ten projekt jest przeznaczony do pracy inżynierskiej.

## Autor

Jarosław Łyczak
