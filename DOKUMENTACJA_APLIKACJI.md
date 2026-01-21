# Rozdział 3 - Dokumentacja aplikacji TowerFlower

## 3.1 Wprowadzenie

TowerFlower to aplikacja mobilna i webowa stworzona w technologii Flutter, przeznaczona do śledzenia lotów w czasie rzeczywistym oraz zarządzania informacjami lotniskowymi. Aplikacja umożliwia użytkownikom wizualizację samolotów na interaktywnej mapie, przeglądanie rozkładów lotów, słuchanie transmisji audio z wież kontrolnych oraz udostępnianie zdjęć samolotów.

### 3.1.1 Cel aplikacji

Głównym celem aplikacji TowerFlower jest dostarczenie kompleksowego narzędzia dla entuzjastów lotnictwa, umożliwiającego:
- Śledzenie lotów w czasie rzeczywistym na interaktywnej mapie
- Przeglądanie szczegółowych informacji o przylotach i odlotach
- Słuchanie transmisji audio z wież kontrolnych lotnisk
- Udostępnianie i przeglądanie zdjęć samolotów
- Zarządzanie ulubionymi lotniskami i strumieniami audio

### 3.1.2 Platformy docelowe

Aplikacja została zaprojektowana jako multiplatformowa, obsługująca:
- **Android** - aplikacja natywna
- **iOS** - aplikacja natywna
- **Web** - aplikacja webowa działająca w przeglądarce
- **Windows** - aplikacja desktopowa
- **Linux** - aplikacja desktopowa
- **macOS** - aplikacja desktopowa

## 3.2 Architektura aplikacji

### 3.2.1 Wzorzec architektoniczny

Aplikacja TowerFlower wykorzystuje architekturę opartą na wzorcu **Model-View-Service (MVS)**, który jest adaptacją klasycznego wzorca MVC dostosowaną do specyfiki frameworka Flutter:

- **Model** - reprezentuje dane aplikacji (modele lotów, lotnisk, zdjęć)
- **View** - ekrany i widżety odpowiedzialne za prezentację danych
- **Service** - serwisy odpowiedzialne za komunikację z API zewnętrznymi i Firebase

### 3.2.2 Struktura katalogów

```
lib/
├── models/              # Modele danych
│   ├── aircraft.dart
│   ├── aircraft_photo.dart
│   ├── airport.dart
│   ├── airport_flight.dart
│   ├── airports_data.dart
│   └── fligth.dart
├── screens/            # Ekrany aplikacji
│   ├── aircraft_details_screen.dart
│   ├── aircraft_photos_screen.dart
│   ├── airport_info_screen.dart
│   ├── airports_management_screen.dart
│   ├── auth_screen.dart
│   ├── flights_board_screen.dart
│   ├── map_screen.dart
│   ├── my_photos_screen.dart
│   ├── settings_screen.dart
│   ├── splash_screen.dart
│   └── streams_management_screen.dart
├── services/           # Serwisy i logika biznesowa
│   ├── airport_info_service.dart
│   ├── airport_search_service.dart
│   ├── firebase_service.dart
│   └── opensky_service.dart
├── widgets/            # Komponenty UI wielokrotnego użytku
├── firebase_options.dart
└── main.dart           # Punkt wejścia aplikacji
```

### 3.2.3 Przepływ danych

Aplikacja wykorzystuje jednokierunkowy przepływ danych (unidirectional data flow):

1. **Użytkownik wykonuje akcję** w interfejsie (np. kliknięcie przycisku)
2. **Ekran (View)** wywołuje odpowiednią metodę w serwisie
3. **Serwis** wykonuje operację (zapytanie do API, operacja na Firebase)
4. **Dane są zwracane** do ekranu
5. **Ekran aktualizuje stan** i odświeża interfejs użytkownika

## 3.3 Technologie i narzędzia

### 3.3.1 Framework Flutter

Aplikacja została zbudowana przy użyciu **Flutter SDK w wersji 3.7.0** lub nowszej. Flutter to framework open-source stworzony przez Google, umożliwiający tworzenie aplikacji multiplatformowych z jednego kodu źródłowego.

**Zalety wyboru Flutter:**
- Jeden kod dla wielu platform
- Wysoka wydajność dzięki kompilacji do kodu natywnego
- Bogaty zestaw gotowych widgetów
- Hot reload dla szybkiego rozwoju
- Wsparcie dla Material Design i Cupertino

### 3.3.2 Język programowania Dart

**Dart** jest językiem programowania używanym przez Flutter. Wersja użyta w projekcie: **^3.7.0**.

**Kluczowe cechy Dart wykorzystane w projekcie:**
- Typowanie statyczne z inferencją typów
- Asynchroniczność z `async/await` i `Future`
- Streams dla reaktywnych danych
- Null safety dla bezpieczeństwa typów

### 3.3.3 Główne biblioteki i zależności

#### 3.3.3.1 Firebase

Aplikacja wykorzystuje kompleksowy zestaw usług Firebase:

- **firebase_core (^3.6.0)** - inicjalizacja Firebase
- **firebase_auth (^5.3.1)** - uwierzytelnianie użytkowników
- **cloud_firestore (^5.4.3)** - baza danych NoSQL w czasie rzeczywistym
- **firebase_storage (^12.3.4)** - przechowywanie plików (zdjęcia samolotów)
- **firebase_analytics (^11.3.3)** - analityka użycia aplikacji
- **firebase_crashlytics (^4.1.3)** - raportowanie błędów i crashy
- **firebase_remote_config (^5.1.3)** - konfiguracja zdalna
- **firebase_messaging (^15.1.3)** - powiadomienia push

#### 3.3.3.2 Mapy i lokalizacja

- **flutter_map (^8.1.1)** - biblioteka map oparta na Leaflet
- **latlong2 (^0.9.0)** - operacje na współrzędnych geograficznych
- **flutter_map_cancellable_tile_provider (^3.1.0)** - optymalizacja ładowania kafelków mapy

#### 3.3.3.3 Komunikacja sieciowa

- **http (^1.3.0)** - klient HTTP do komunikacji z API zewnętrznymi

#### 3.3.3.4 Media i multimedia

- **just_audio (^0.10.4)** - odtwarzanie strumieni audio z wież kontrolnych
- **image_picker (^1.1.2)** - wybór zdjęć z urządzenia
- **cached_network_image (^3.4.1)** - cache'owanie obrazów z sieci

#### 3.3.3.5 Inne biblioteki

- **shared_preferences (^2.3.3)** - przechowywanie prostych danych lokalnych
- **flutter_dotenv (^5.2.1)** - zarządzanie zmiennymi środowiskowymi
- **flutter_animate (^4.2.0)** - animacje UI
- **collection (^1.18.0)** - dodatkowe kolekcje Dart

### 3.3.4 Narzędzia deweloperskie

- **flutter_lints (^5.0.0)** - reguły lintowania kodu
- **mockito (^5.4.4)** - tworzenie mocków do testów
- **build_runner (^2.4.8)** - generowanie kodu

## 3.4 Modele danych

### 3.4.1 Flight

Model reprezentujący lot w czasie rzeczywistym z API OpenSky Network.

```dart
class Flight {
  final String icao24;           // Unikalny identyfikator samolotu (24-bitowy)
  final String callsign;         // Znak wywoławczy lotu
  final double latitude;         // Szerokość geograficzna
  final double longitude;        // Długość geograficzna
  final double heading;          // Kierunek lotu (0-360°)
  final double velocity;         // Prędkość (m/s)
  final double altitude;         // Wysokość (m)
  final bool onGround;           // Czy samolot jest na ziemi
  final String originCountry;    // Kraj pochodzenia
}
```

**Źródło danych:** OpenSky Network API (`/states/all`)

### 3.4.2 Airport

Model reprezentujący lotnisko.

```dart
class Airport {
  final String icao;             // Kod ICAO lotniska (4 znaki)
  final String name;             // Nazwa lotniska
  final LatLng location;         // Współrzędne geograficzne
  final String? liveStreamUrl;    // URL strumienia audio (opcjonalny)
}
```

### 3.4.3 AirportFlight

Model reprezentujący lot w rozkładzie lotów (przyloty/odloty).

```dart
class AirportFlight {
  final String? flightNumber;        // Numer lotu
  final String? airline;             // Nazwa linii lotniczej
  final String? codesharedNumber;    // Numer lotu codeshare
  final String? aircraft;            // Rejestracja samolotu (IATA/ICAO)
  final String? aircraftType;        // Kod typu statku (np. "B738", "A320", "H")
  final String? destination;         // Lotnisko docelowe (IATA/ICAO)
  final String? origin;              // Lotnisko pochodzenia (IATA/ICAO)
  final DateTime? scheduledTime;     // Planowany czas
  final DateTime? estimatedTime;     // Szacowany czas
  final DateTime? actualTime;        // Rzeczywisty czas
  final String? status;              // Status lotu ("On Time", "Delayed", "Landed", "Departed", etc.)
  final String? gate;                // Numer bramki
  final String? terminal;            // Numer terminala
  
  // Właściwość obliczana
  AircraftCategory get category;     // Kategoria statku powietrznego
}
```

**Kategoryzacja statków powietrznych:**

Model zawiera enum `AircraftCategory` z następującymi wartościami:
- `small` - Małe samoloty (np. C172, PA28)
- `medium` - Średnie samoloty (np. B737, A320)
- `large` - Duże samoloty (np. B777, A380)
- `helicopter` - Helikoptery (H)
- `unknown` - Nieznany typ

Kategoryzacja odbywa się automatycznie na podstawie kodu typu statku (`aircraftType`).

**Źródło danych:** Aviationstack API

### 3.4.4 Aircraft

Model reprezentujący samolot w czasie rzeczywistym z rozszerzonymi informacjami.

```dart
class Aircraft {
  final String icao24;           // Unikalny identyfikator samolotu (24-bitowy)
  final String callsign;         // Znak wywoławczy lotu
  final String originCountry;    // Kraj pochodzenia
  final double longitude;        // Długość geograficzna
  final double latitude;         // Szerokość geograficzna
  final double altitude;         // Wysokość (m)
  final double velocity;         // Prędkość (m/s)
  final double heading;          // Kierunek lotu (0-360°)
  final String departureIcao;   // Kod ICAO lotniska odlotu
  final String arrivalIcao;      // Kod ICAO lotniska przylotu
  final String? aircraftType;    // Kod typu statku (np. "B738", "A320", "H")
  
  // Właściwość obliczana
  AircraftCategory get category; // Kategoria statku powietrznego
}
```

**Kategoryzacja statków:**

Model automatycznie kategoryzuje statek powietrzny na podstawie:
- Kodu typu statku (`aircraftType`) - jeśli dostępny
- Heurystyki opartej na callsign, prędkości i wysokości - jeśli kod typu nie jest dostępny

**Źródło danych:** OpenSky Network API (rozszerzony model Flight)

### 3.4.5 AircraftPhoto

Model reprezentujący zdjęcie samolotu przesłane przez użytkownika.

```dart
class AircraftPhoto {
  final String id;               // Unikalny identyfikator
  final String airportIcao;      // Kod ICAO lotniska
  final String imageUrl;         // URL zdjęcia w Firebase Storage
  final String? aircraftRegistration; // Rejestracja samolotu
  final String? flightNumber;    // Numer lotu
  final String? description;     // Opis zdjęcia
  final String? uploadedBy;      // UID użytkownika (opcjonalne)
  final String? uploadedByEmail; // Email użytkownika (opcjonalne)
  final DateTime uploadedAt;    // Data przesłania
  final int likes;              // Liczba polubień
}
```

## 3.5 Serwisy aplikacji

### 3.5.1 OpenSkyService

Serwis odpowiedzialny za komunikację z API OpenSky Network - darmowym API dostarczającym dane o lotach w czasie rzeczywistym.

**Główne metody:**

- `fetchFlights()` - pobiera listę lotów w określonym obszarze geograficznym
  - Parametry: `lamin`, `lomin`, `lamax`, `lomax` (granice obszaru)
  - Zwraca: `List<Flight>`
  
- `fetchFlightTrack()` - pobiera historyczną trasę lotu dla danego samolotu
  - Parametr: `icao24` (identyfikator samolotu)
  - Zwraca: `List<LatLng>` (lista punktów trasy)

**Endpoint API:**
- Base URL: `https://opensky-network.org/api`
- Endpoint lotów: `/states/all`
- Endpoint trasy: `/tracks/all`

**Ograniczenia API:**
- OpenSky Network jest darmowe i nie wymaga klucza API
- Rate limiting: ~10 zapytań na sekundę
- Dane dostępne tylko dla lotów w zasięgu stacji naziemnych

### 3.5.2 AirportInfoService

Serwis odpowiedzialny za pobieranie szczegółowych informacji o lotach z Aviationstack API.

**Główne metody:**

- `fetchArrivals()` - pobiera przyloty dla danego lotniska
  - Parametry: `airportIcao` (kod ICAO), `hoursRange` (zakres godzin, domyślnie 1)
  - Zwraca: `List<AirportFlight>`
  - Filtruje loty w zakresie: -30 minut do +X godzin od aktualnego czasu

- `fetchDepartures()` - pobiera odloty dla danego lotniska
  - Parametry: `airportIcao` (kod ICAO), `hoursRange` (zakres godzin, domyślnie 1)
  - Zwraca: `List<AirportFlight>`
  - Filtruje loty w zakresie: -30 minut do +X godzin od aktualnego czasu

- `setApiKey()` - ustawia klucz API Aviationstack

**Endpoint API:**
- Base URL: `https://api.aviationstack.com/v1`
- Endpoint: `/flights`
- Parametry: `access_key`, `arr_icao` (przyloty) lub `dep_icao` (odloty), `limit`

**Wymagania:**
- Wymaga klucza API z Aviationstack (darmowy plan dostępny)
- Klucz może być przechowywany lokalnie lub w Firebase dla zalogowanych użytkowników

### 3.5.3 FirebaseService

Centralny serwis zarządzający wszystkimi operacjami związanymi z Firebase. Implementuje wzorzec Singleton.

**Główne funkcjonalności:**

#### 3.5.3.1 Uwierzytelnianie użytkowników

- `signInWithEmailAndPassword()` - logowanie użytkownika
- `createUserWithEmailAndPassword()` - rejestracja nowego użytkownika
- `signOut()` - wylogowanie użytkownika
- `currentUser` - aktualnie zalogowany użytkownik
- `authStateChanges` - stream zmian stanu uwierzytelniania

#### 3.5.3.2 Zarządzanie preferencjami użytkownika

- `saveUserPreferences()` - zapisuje preferencje użytkownika (ulubione lotnisko, język, powiadomienia)
- `getUserPreferences()` - pobiera preferencje użytkownika
- `saveApiKeyToFirebase()` - zapisuje klucz API Aviationstack w Firebase
- `getApiKeyFromFirebase()` - pobiera klucz API z Firebase

#### 3.5.3.3 Zarządzanie strumieniami audio

- `saveUserStream()` - zapisuje strumień audio dla lotniska
- `getUserStreamsForAirport()` - pobiera wszystkie strumienie dla lotniska
- `getAllUserStreams()` - pobiera wszystkie strumienie użytkownika
- `deleteUserStream()` - usuwa strumień

**Obsługa użytkowników niezalogowanych:**
- Dla użytkowników niezalogowanych strumienie są przechowywane lokalnie w pamięci aplikacji
- Dane są tracone po zamknięciu aplikacji

#### 3.5.3.4 Zarządzanie danymi lotnisk

- `saveAirportData()` - zapisuje dane lotniska w Firestore
- `getAirports()` - pobiera listę wszystkich lotnisk

#### 3.5.3.5 Zarządzanie zdjęciami samolotów

- `uploadAircraftPhoto()` - przesyła zdjęcie samolotu do Firebase Storage i zapisuje metadane w Firestore
- `getAircraftPhotos()` - pobiera stream zdjęć dla danego lotniska (w czasie rzeczywistym)
- `getMyAircraftPhotos()` - pobiera stream zdjęć przesłanych przez aktualnego użytkownika
- `deleteAircraftPhoto()` - usuwa zdjęcie (tylko własne)
- `likeAircraftPhoto()` - dodaje polubienie do zdjęcia

**Struktura danych w Firestore:**

```
users/
  {userId}/
    - favoriteAirport: String
    - notificationsEnabled: Boolean
    - language: String
    - aviationstackApiKey: String?
    streams/
      {streamId}/
        - airportIcao: String
        - streamUrl: String
        - streamName: String
        - createdAt: Timestamp
        - lastUpdated: Timestamp

airports/
  {icao}/
    - icao: String
    - name: String
    - location: GeoPoint
    - liveStreamUrl: String
    - lastUpdated: Timestamp

aircraft_photos/
  {photoId}/
    - airportIcao: String
    - imageUrl: String
    - aircraftRegistration: String?
    - flightNumber: String?
    - description: String?
    - uploadedBy: String
    - uploadedByEmail: String?
    - uploadedAt: Timestamp
    - likes: Number

flight_tracking/
  {trackId}/
    - icao24: String
    - callsign: String
    - airport: String
    - latitude: Number
    - longitude: Number
    - heading: Number
    - timestamp: Timestamp
    - userId: String?
```

#### 3.5.3.6 Analityka i monitoring

- `logScreenView()` - loguje wyświetlenie ekranu
- `logCustomEvent()` - loguje niestandardowe zdarzenie
- Wszystkie operacje automatycznie logują odpowiednie zdarzenia do Firebase Analytics

#### 3.5.3.7 Remote Config

- `initializeRemoteConfig()` - inicjalizuje Remote Config
- `getString()`, `getBool()`, `getInt()`, `getDouble()` - pobiera wartości konfiguracyjne

### 3.5.4 AirportSearchService

Serwis odpowiedzialny za wyszukiwanie lotnisk (implementacja może być rozszerzona w przyszłości).

## 3.6 Ekrany aplikacji

### 3.6.1 SplashScreen

Ekran startowy aplikacji wyświetlany przy uruchomieniu.

**Funkcjonalności:**
- Wyświetla logo aplikacji
- Sprawdza stan uwierzytelniania użytkownika
- Przekierowuje do odpowiedniego ekranu:
  - `/auth` - jeśli użytkownik nie jest zalogowany
  - `/map` - jeśli użytkownik jest zalogowany

### 3.6.2 AuthScreen

Ekran uwierzytelniania użytkowników.

**Funkcjonalności:**
- Logowanie użytkownika (email + hasło)
- Rejestracja nowego użytkownika
- Obsługa błędów uwierzytelniania
- Przekierowanie do ekranu mapy po pomyślnym zalogowaniu

### 3.6.3 MapScreen

Główny ekran aplikacji - interaktywna mapa z lotami w czasie rzeczywistym.

**Funkcjonalności:**

#### 3.6.3.1 Wyświetlanie mapy

- Interaktywna mapa wykorzystująca bibliotekę `flutter_map`
- Obsługa wielu warstw mapowych:
  - OpenStreetMap Standard
  - OpenStreetMap HOT
  - OpenTopoMap
- Zoom, przesuwanie, gesty dotykowe
- Kontroler mapy do programowego sterowania

#### 3.6.3.2 Wyświetlanie lotów

- Markery samolotów na mapie z ikonami wskazującymi kierunek lotu
- Automatyczne odświeżanie danych co kilka sekund (timer `_apiRefreshTimer`)
- Filtrowanie lotów według obszaru widocznego na mapie (tylko samoloty w widocznym obszarze)
- Wyświetlanie informacji o locie po kliknięciu markera:
  - Znak wywoławczy (callsign)
  - Wysokość (w metrach)
  - Prędkość (w m/s)
  - Kierunek (w stopniach, 0-360°)
  - Kraj pochodzenia
  - Możliwość rozpoczęcia śledzenia lotu
- Filtrowanie lotów na ziemi (opcjonalne)
- Kategoryzacja statków powietrznych (małe/średnie/duże samoloty, helikoptery)

#### 3.6.3.3 Wybór lotniska

- Lista dostępnych lotnisk z możliwością wyboru
- Automatyczne centrowanie mapy na wybranym lotnisku
- Wyświetlanie markera lotniska na mapie
- Domyślna lista lotnisk polskich (EPKK, EPWA, EPGD, EPPO, EPLL, EPKT, EPBY, EPSC, EPWR, EPMO, EPOK, EPRZ, EPRA)
- Możliwość synchronizacji lotnisk z Firebase Firestore
- Łączenie lotnisk z Firebase z domyślną listą (bez duplikatów)

#### 3.6.3.4 Śledzenie lotu na żywo (Live Tracking)

- Możliwość wybrania samolotu do śledzenia przez kliknięcie markera
- Automatyczne odświeżanie pozycji śledzonego samolotu (co 2-3 sekundy)
- Wyświetlanie postępującej trasy lotu (linia łącząca kolejne pozycje w czasie rzeczywistym)
- Wyświetlanie historycznej trasy lotu (z API OpenSky Network `/tracks/all`)
- Automatyczne centrowanie mapy na śledzonym samolocie
- Wskaźnik prędkości i kierunku lotu
- Wyświetlanie callsign śledzonego samolotu
- Możliwość zatrzymania śledzenia

**Implementacja:**
- Timer odświeżający pozycję co 2-3 sekundy (`_liveTrackingTimer`)
- Przechowywanie historii pozycji w `_trackedFlightPath` (postępująca trasa)
- Przechowywanie historycznej trasy w `_historicalFlightPath` (z API)
- Rysowanie polilinii reprezentującej trasę na mapie
- Automatyczne czyszczenie timera przy zmianie śledzonego samolotu lub opuszczeniu ekranu

#### 3.6.3.5 Odtwarzanie strumieni audio

- Lista dostępnych strumieni audio dla wybranego lotniska
- Odtwarzanie strumienia audio z wieży kontrolnej
- Kontrola odtwarzania (play/pause)
- Wyświetlanie nazwy aktualnie odtwarzanego strumienia
- Automatyczne zatrzymanie przy zmianie lotniska

**Implementacja:**
- Wykorzystanie biblioteki `just_audio`
- Obsługa URL strumieni audio (np. Icecast, Shoutcast)
- Automatyczne zatrzymanie odtwarzania przy zmianie lotniska lub opuszczeniu ekranu
- Wyświetlanie nazwy aktualnie odtwarzanego strumienia
- Obsługa błędów połączenia ze strumieniem

#### 3.6.3.6 Nawigacja do innych ekranów

- Przycisk do ekranu rozkładu lotów (`/flights`)
- Przycisk do ekranu ustawień (`/settings`)
- Przycisk do zarządzania strumieniami (`/streams`)
- Przycisk do informacji o lotnisku (`/airport_info`)
- Przycisk do galerii zdjęć (`/aircraft_photos`)

### 3.6.4 FlightsBoardScreen

Ekran wyświetlający rozkład lotów dla wybranego lotniska.

**Funkcjonalności:**
- Wyświetlanie przylotów i odlotów w osobnych zakładkach
- Filtrowanie lotów według czasu (domyślnie ±1 godzina)
- Szczegółowe informacje o każdym locie:
  - Numer lotu
  - Rejestracja samolotu
  - Planowany/szacowany/rzeczywisty czas
  - Status lotu
  - Lotnisko pochodzenia/przeznaczenia
- Odświeżanie danych
- Możliwość wyboru innego lotniska

**Źródło danych:** Aviationstack API przez `AirportInfoService` (dla przylotów/odlotów) oraz OpenSky Network API (dla lotów w czasie rzeczywistym)

### 3.6.5 AirportInfoScreen

Ekran z szczegółowymi informacjami o lotnisku.

**Funkcjonalności:**
- Wyświetlanie podstawowych informacji o lotnisku
- Lista nadchodzących przylotów
- Lista nadchodzących odlotów
- Link do mapy z centrowaniem na lotnisku

### 3.6.6 AircraftPhotosScreen

Ekran galerii zdjęć samolotów dla danego lotniska.

**Funkcjonalności:**
- Wyświetlanie zdjęć przesłanych przez użytkowników
- Grid layout z miniaturkami zdjęć
- Szczegóły zdjęcia po kliknięciu:
  - Pełny obraz
  - Rejestracja samolotu
  - Numer lotu
  - Opis
  - Autor
  - Data przesłania
  - Liczba polubień
- Możliwość polubienia zdjęcia
- Stream w czasie rzeczywistym - nowe zdjęcia pojawiają się automatycznie

**Źródło danych:** Firebase Firestore (kolekcja `aircraft_photos`)

### 3.6.7 MyPhotosScreen

Ekran wyświetlający zdjęcia przesłane przez aktualnego użytkownika.

**Funkcjonalności:**
- Lista wszystkich zdjęć przesłanych przez użytkownika
- Możliwość usunięcia własnych zdjęć
- Szczegóły każdego zdjęcia
- Filtrowanie według lotniska

### 3.6.8 StreamsManagementScreen

Ekran zarządzania strumieniami audio.

**Funkcjonalności:**
- Lista wszystkich strumieni użytkownika
- Dodawanie nowego strumienia:
  - Wybór lotniska (kod ICAO)
  - Wprowadzenie URL strumienia
  - Opcjonalna nazwa strumienia
- Edycja istniejącego strumienia
- Usuwanie strumienia
- Dla użytkowników niezalogowanych: strumienie przechowywane lokalnie

### 3.6.9 SettingsScreen

Ekran ustawień aplikacji.

**Funkcjonalności:**
- Wyświetlanie informacji o zalogowanym użytkowniku
- Wylogowanie
- Zarządzanie kluczem API Aviationstack:
  - Wprowadzenie klucza API
  - Zapis klucza lokalnie lub w Firebase
- Ustawienia preferencji użytkownika:
  - Ulubione lotnisko
  - Włączanie/wyłączanie powiadomień
  - Wybór języka

### 3.6.10 AircraftDetailsScreen

Ekran szczegółów samolotu (może być używany do wyświetlania dodatkowych informacji o wybranym samolocie).

### 3.6.11 AirportsManagementScreen

Ekran zarządzania lotniskami.

**Funkcjonalności:**
- Wyświetlanie listy dostępnych lotnisk
- Dodawanie nowych lotnisk do bazy danych
- Edycja danych lotnisk
- Usuwanie lotnisk
- Synchronizacja z Firebase Firestore

## 3.7 Integracje z zewnętrznymi API

### 3.7.1 OpenSky Network API

**Opis:** Darmowe API dostarczające dane o lotach w czasie rzeczywistym.

**Endpointy używane:**
- `GET /api/states/all` - pobiera wszystkie loty w określonym obszarze
- `GET /api/tracks/all` - pobiera historyczną trasę lotu

**Parametry zapytań:**
- `lamin`, `lomin`, `lamax`, `lomax` - granice obszaru geograficznego
- `icao24` - identyfikator samolotu (dla trasy)
- `time` - znacznik czasu (dla trasy)

**Odpowiedź API:**
```json
{
  "time": 1234567890,
  "states": [
    [
      "icao24",
      "callsign",
      "origin_country",
      ...
    ]
  ]
}
```

**Obsługa błędów:**
- Status 200: sukces
- Inne statusy: rzucany wyjątek z komunikatem błędu

**Rate limiting:**
- ~10 zapytań na sekundę
- Aplikacja implementuje odświeżanie co kilka sekund

**Endpoint trasy lotu:**
- `GET /api/tracks/all?icao24={icao24}&time={timestamp}` - pobiera historyczną trasę lotu
- Zwraca listę punktów trasy w formacie `[[timestamp, latitude, longitude], ...]`

### 3.7.2 Aviationstack API

**Opis:** Płatne API dostarczające szczegółowe informacje o lotach, przylotach i odlotach.

**Endpointy używane:**
- `GET /v1/flights` - pobiera loty (przyloty lub odloty)

**Parametry zapytań:**
- `access_key` - klucz API użytkownika
- `arr_icao` - kod ICAO lotniska przylotu (dla przylotów)
- `dep_icao` - kod ICAO lotniska odlotu (dla odlotów)
- `limit` - maksymalna liczba wyników (domyślnie 100)

**Odpowiedź API:**
```json
{
  "pagination": {...},
  "data": [
    {
      "flight": {...},
      "aircraft": {...},
      "airline": {...},
      "departure": {...},
      "arrival": {...}
    }
  ]
}
```

**Obsługa błędów:**
- Status 200: sukces
- Status 401: nieprawidłowy klucz API
- Status 429: przekroczony limit zapytań
- Inne: rzucany wyjątek z komunikatem błędu

**Filtrowanie po stronie klienta:**
- API zwraca wszystkie dostępne loty (limit 100)
- Aplikacja filtruje loty według czasu lokalnego:
  - Zakres: -30 minut do +X godzin (+60 minut bufor) od aktualnego czasu
  - Używa `actualTime` jeśli dostępne, w przeciwnym razie `scheduledTime` lub `estimatedTime`
  - Sortowanie według czasu planowanego/szacowanego/rzeczywistego (rosnąco)
- Obsługa czasów UTC z API - konwersja do czasu lokalnego urządzenia

**Przechowywanie klucza API:**
- Lokalnie w SharedPreferences (dla wszystkich użytkowników)
- W Firebase Firestore (dla zalogowanych użytkowników, opcjonalnie)

## 3.8 Baza danych Firebase

### 3.8.1 Firebase Firestore

Firestore to NoSQL baza danych w czasie rzeczywistym używana do przechowywania danych aplikacji.

**Uwaga:** Aplikacja została zaprojektowana tak, aby mogła działać również bez Firebase (tryb offline). W przypadku błędu inicjalizacji Firebase, aplikacja kontynuuje działanie z ograniczoną funkcjonalnością (brak synchronizacji danych, brak uwierzytelniania).

**Struktura kolekcji:**

#### users/{userId}
Dane użytkownika i preferencje.
```
{
  favoriteAirport: String,
  notificationsEnabled: Boolean,
  language: String,
  aviationstackApiKey: String?,
  lastUpdated: Timestamp
}
```

#### users/{userId}/streams/{streamId}
Strumienie audio użytkownika.
```
{
  airportIcao: String,
  streamUrl: String,
  streamName: String,
  createdAt: Timestamp,
  lastUpdated: Timestamp
}
```

#### airports/{icao}
Dane lotnisk.
```
{
  icao: String,
  name: String,
  location: GeoPoint,
  liveStreamUrl: String?,
  lastUpdated: Timestamp
}
```

#### aircraft_photos/{photoId}
Metadane zdjęć samolotów.
```
{
  airportIcao: String,
  imageUrl: String,
  aircraftRegistration: String?,
  flightNumber: String?,
  description: String?,
  uploadedBy: String,
  uploadedByEmail: String?,
  uploadedAt: Timestamp,
  likes: Number
}
```

#### flight_tracking/{trackId}
Dane śledzenia lotów (opcjonalne, do analityki).
```
{
  icao24: String,
  callsign: String,
  airport: String,
  latitude: Number,
  longitude: Number,
  heading: Number,
  timestamp: Timestamp,
  userId: String?
}
```

**Indeksy Firestore:**
- `aircraft_photos`: indeks złożony na `airportIcao` + `uploadedAt` (descending)
- `aircraft_photos`: indeks złożony na `uploadedBy` + `uploadedAt` (descending)
- `users/{userId}/streams`: indeks na `airportIcao`

### 3.8.2 Firebase Storage

Firebase Storage używany do przechowywania zdjęć samolotów.

**Struktura:**
```
aircraft_photos/
  {airportIcao}/
    {timestamp}_{filename}
```

**Reguły bezpieczeństwa:**
- Zapis: tylko zalogowani użytkownicy
- Odczyt: wszyscy użytkownicy
- Usuwanie: tylko właściciel zdjęcia

### 3.8.3 Firebase Authentication

Uwierzytelnianie użytkowników przez email i hasło.

**Metody:**
- Email/Password authentication
- Automatyczne zarządzanie sesją
- Obsługa resetowania hasła (możliwość rozszerzenia)

### 3.8.4 Firebase Analytics

Automatyczne śledzenie zdarzeń w aplikacji:
- Wyświetlenia ekranów
- Logowanie/wylogowanie
- Przesyłanie zdjęć
- Zapisywanie strumieni
- Błędy i wyjątki

### 3.8.5 Firebase Crashlytics

Automatyczne raportowanie crashy i błędów aplikacji.

**Implementacja:**
- Tylko dla platform natywnych (Android, iOS)
- Na platformie web: logowanie do konsoli
- Przechwytywanie wszystkich nieobsłużonych błędów Flutter

### 3.8.6 Firebase Remote Config

Konfiguracja zdalna aplikacji (możliwość dynamicznej zmiany parametrów bez aktualizacji aplikacji).

**Użycie:**
- Inicjalizacja przy starcie aplikacji
- Możliwość konfiguracji limitów, URL-i, itp.

## 3.9 Bezpieczeństwo

### 3.9.1 Uwierzytelnianie

- Wszystkie wrażliwe operacje wymagają zalogowania użytkownika
- Firebase Authentication zapewnia bezpieczne przechowywanie danych uwierzytelniających
- Hasła są hashowane przez Firebase (nie przechowywane w plain text)

### 3.9.2 Reguły bezpieczeństwa Firestore

**Przykładowe reguły (do zdefiniowania w Firebase Console):**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Użytkownicy mogą czytać i pisać tylko swoje dane
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /streams/{streamId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Lotniska - odczyt dla wszystkich, zapis tylko dla zalogowanych
    match /airports/{airportId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Zdjęcia - odczyt dla wszystkich, zapis tylko dla zalogowanych
    match /aircraft_photos/{photoId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                     request.resource.data.uploadedBy == request.auth.uid;
      allow delete: if request.auth != null && 
                     resource.data.uploadedBy == request.auth.uid;
    }
  }
}
```

### 3.9.3 Przechowywanie kluczy API

- Klucze API Aviationstack przechowywane lokalnie lub w Firebase
- Nie są hardkodowane w kodzie źródłowym
- Dla użytkowników zalogowanych: opcjonalne przechowywanie w Firebase (szyfrowane)
- OpenSky Network API jest darmowe i nie wymaga klucza

### 3.9.4 Obsługa błędów

- Wszystkie operacje sieciowe mają obsługę błędów
- Komunikaty błędów nie ujawniają wrażliwych informacji
- Błędy są logowane do Firebase Crashlytics dla analizy

## 3.10 Testy

### 3.10.1 Struktura testów

Projekt zawiera testy jednostkowe w katalogu `test/`:

- `flight_model_test.dart` - testy modelu Flight
- `flights_board_screen_test.dart` - testy ekranu rozkładu lotów
- `map_screen_live_tracking_test.dart` - testy funkcjonalności śledzenia na żywo

### 3.10.2 Narzędzia testowe

- `flutter_test` - framework testowy Flutter
- `mockito` - tworzenie mocków dla testów jednostkowych
- `build_runner` - generowanie kodu dla mockito

### 3.10.3 Uruchamianie testów

```bash
flutter test
```

## 3.11 Wydajność i optymalizacja

### 3.11.1 Optymalizacja mapy

- Użycie `flutter_map_cancellable_tile_provider` do anulowania niepotrzebnych żądań kafelków
- Cache'owanie kafelków mapy
- Ograniczenie liczby markerów na mapie (filtrowanie według obszaru widocznego)

### 3.11.2 Optymalizacja obrazów

- Użycie `cached_network_image` do cache'owania zdjęć
- Lazy loading zdjęć w galerii
- Kompresja obrazów przed przesłaniem do Firebase Storage

### 3.11.3 Optymalizacja zapytań API

- Throttling zapytań do API (odświeżanie co kilka sekund)
- Filtrowanie danych po stronie klienta, gdy API nie wspiera filtrowania
- Cache'owanie danych, gdy to możliwe

### 3.11.4 Streams w czasie rzeczywistym

- Wykorzystanie Firestore streams zamiast okresowego polling'u
- Automatyczne aktualizacje UI przy zmianie danych
- Minimalizacja liczby subskrypcji

## 3.12 Obsługa błędów i wyjątków

### 3.12.1 Strategia obsługi błędów

- Wszystkie operacje asynchroniczne są opakowane w try-catch
- Komunikaty błędów są wyświetlane użytkownikowi w czytelnej formie
- Błędy są logowane do Firebase Crashlytics (dla platform natywnych)
- Na platformie web błędy są logowane do konsoli przeglądarki
- Aplikacja może działać w trybie degradowanym (bez Firebase) w przypadku błędów inicjalizacji
- Obsługa błędów sieciowych z możliwością ponowienia operacji

### 3.12.2 Typowe scenariusze błędów

- **Brak połączenia internetowego** - wyświetlanie komunikatu, aplikacja działa w trybie offline
- **Błąd inicjalizacji Firebase** - aplikacja kontynuuje działanie z ograniczoną funkcjonalnością
- **Błąd uwierzytelniania** - komunikat z możliwością ponowienia, szczegółowy komunikat błędu
- **Błąd API (401, 429, itp.)** - odpowiedni komunikat dla użytkownika:
  - 401: Nieprawidłowy klucz API
  - 429: Przekroczono limit zapytań - sugestia ponowienia za chwilę
  - Inne: Ogólny komunikat błędu z kodem statusu
- **Błąd przesyłania zdjęcia** - komunikat z możliwością ponowienia
- **Błąd odtwarzania strumienia audio** - komunikat i automatyczne zatrzymanie odtwarzania
- **Błąd pobierania lotów** - wyświetlanie komunikatu, możliwość ręcznego odświeżenia

## 3.13 Lokalizacja i internacjonalizacja

### 3.13.1 Języki

- Aplikacja obecnie obsługuje język polski
- Struktura pozwala na łatwe dodanie innych języków
- Preferencje języka przechowywane w Firebase

### 3.13.2 Formatowanie danych

- Czas: formatowanie według lokalizacji urządzenia
- Współrzędne geograficzne: stopnie dziesiętne
- Prędkość: m/s (możliwość konwersji do km/h lub węzłów)

## 3.14 Wymagania systemowe

### 3.14.1 Minimalne wymagania

**Android:**
- Android 5.0 (API level 21) lub nowszy
- Połączenie internetowe

**iOS:**
- iOS 12.0 lub nowszy
- Połączenie internetowe

**Web:**
- Nowoczesna przeglądarka z obsługą JavaScript ES6+
- Połączenie internetowe

### 3.14.2 Wymagane uprawnienia

**Android:**
- `INTERNET` - dostęp do internetu
- `ACCESS_NETWORK_STATE` - sprawdzanie stanu sieci
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - dostęp do zdjęć (opcjonalnie)

**iOS:**
- Uprawnienia do kamery/galerii (opcjonalnie, dla przesyłania zdjęć)

## 3.15 Instalacja i konfiguracja

### 3.15.1 Wymagania deweloperskie

- Flutter SDK ^3.7.0
- Dart SDK (zawarty w Flutter)
- Android Studio / Xcode (dla platform natywnych)
- Git

### 3.15.2 Konfiguracja projektu

1. **Sklonowanie repozytorium:**
```bash
git clone <repository_url>
cd flutter_application
```

2. **Instalacja zależności:**
```bash
flutter pub get
```

3. **Konfiguracja Firebase (opcjonalnie, ale zalecane):**
```bash
flutterfire configure
```
Lub ręczna konfiguracja plików `google-services.json` (Android) i `GoogleService-Info.plist` (iOS).

**Uwaga:** Aplikacja może działać bez Firebase, ale z ograniczoną funkcjonalnością:
- Brak uwierzytelniania użytkowników
- Brak synchronizacji danych między urządzeniami
- Brak przechowywania zdjęć w chmurze
- Strumienie audio przechowywane tylko lokalnie

4. **Konfiguracja klucza API Aviationstack (opcjonalnie):**
- Utworzenie pliku `.env` z kluczem API: `AVIATIONSTACK_API_KEY=twój_klucz`
- Lub ustawienie klucza przez interfejs aplikacji w ekranie ustawień
- Klucz może być przechowywany lokalnie (SharedPreferences) lub w Firebase dla zalogowanych użytkowników
- Klucz jest wymagany tylko dla funkcji przylotów/odlotów w `AirportInfoScreen`

5. **Uruchomienie aplikacji:**
```bash
flutter run
```

**Uruchomienie na konkretnej platformie:**
```bash
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run -d android         # Android
flutter run -d ios             # iOS
```

### 3.15.3 Konfiguracja Firebase

Szczegółowe instrukcje konfiguracji Firebase znajdują się w pliku `FIREBASE_SETUP.md`.

## 3.16 Podsumowanie

Aplikacja TowerFlower jest kompleksowym rozwiązaniem multiplatformowym do śledzenia lotów i zarządzania informacjami lotniskowymi. Wykorzystuje nowoczesne technologie takie jak Flutter, Firebase i zewnętrzne API, zapewniając użytkownikom bogate funkcjonalności w intuicyjnym interfejsie.

**Kluczowe cechy architektury:**
- Modularna struktura kodu
- Separacja odpowiedzialności (MVS)
- Wykorzystanie wzorców projektowych (Singleton dla serwisów)
- Reaktywne programowanie (Streams)
- Obsługa błędów na wszystkich poziomach
- Graceful degradation - aplikacja może działać bez Firebase
- Optymalizacja wydajności (cache'owanie, throttling, cancellable requests)

**Główne funkcjonalności:**
- Śledzenie lotów w czasie rzeczywistym na interaktywnej mapie
- Live tracking wybranego samolotu z postępującą trasą
- Interaktywna mapa z wieloma warstwami (OSM Standard, OSM HOT, Topo)
- Rozkłady lotów z szczegółowymi informacjami (przyloty/odloty)
- Kategoryzacja statków powietrznych (małe/średnie/duże samoloty, helikoptery)
- Odtwarzanie strumieni audio z wież kontrolnych
- Galeria zdjęć samolotów z systemem polubień
- Zarządzanie preferencjami użytkownika
- Zarządzanie lotniskami i strumieniami audio
- Uwierzytelnianie użytkowników (opcjonalne)

**Wersja aplikacji:** 1.0.0+1

Aplikacja jest gotowa do użycia i może być dalej rozwijana o dodatkowe funkcjonalności zgodnie z potrzebami użytkowników.

