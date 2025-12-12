# TowerFlower

Aplikacja Flutter do śledzenia lotów i zarządzania informacjami lotniskowymi.

## Funkcjonalności

- 🗺️ Interaktywna mapa lotów z samolotami w czasie rzeczywistym
- ✈️ Lista lotów w okolicy wybranego lotniska
- 📊 Informacje o przylotach i odlotach
- 📸 Galeria zdjęć samolotów
- 🎧 Streamy audio z wież kontrolnych
- 🔴 Śledzenie wybranego samolotu na żywo z postępującą trasą

## Wymagania

- Flutter SDK ^3.7.0
- Dart SDK
- Firebase (dla funkcji społecznościowych)
- Klucz API Aviationstack (opcjonalnie, dla szczegółowych informacji o lotach)

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

3. Skonfiguruj Firebase:
```bash
flutterfire configure
```

4. Dodaj klucz API Aviationstack (opcjonalnie):
   - Utwórz plik `.env` w katalogu głównym
   - Dodaj: `AVIATIONSTACK_API_KEY=twój_klucz`
   - Lub użyj metody `AirportInfoService().setApiKey('twój_klucz')`

5. Uruchom aplikację:
```bash
flutter run
```

## Konfiguracja API

### Aviationstack API
Aby uzyskać szczegółowe informacje o lotach, potrzebujesz klucza API z [Aviationstack](https://aviationstack.com/).

Po uzyskaniu klucza:
- Ustaw go przez zmienną środowiskową `.env`
- Lub użyj metody `setApiKey()` w kodzie

### OpenSky Network
Aplikacja używa darmowego API OpenSky Network do śledzenia lotów w czasie rzeczywistym. Nie wymaga klucza API.

## Testy

Uruchom testy automatyczne:
```bash
flutter test
```

## Struktura projektu

```
lib/
├── models/          # Modele danych
├── screens/         # Ekrany aplikacji
├── services/        # Serwisy API i Firebase
└── widgets/         # Komponenty UI
```

## Licencja

Ten projekt jest przeznaczony do pracy inżynierskiej.

## Autor

Twój projekt inżynierski - TowerFlower
