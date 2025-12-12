# Konfiguracja Firebase dla TowerFlower

## Wymagane kroki do pełnej integracji Firebase

### 1. Utwórz projekt Firebase

1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Kliknij "Dodaj projekt"
3. Wprowadź nazwę projektu: `towerflower-app`
4. Włącz Google Analytics (opcjonalnie)
5. Utwórz projekt

### 2. Dodaj aplikację Android

1. W konsoli Firebase kliknij "Dodaj aplikację" → Android
2. Wprowadź package name: `com.example.flutter_application`
3. Pobierz plik `google-services.json`
4. Zastąp plik `android/app/google-services.json` pobranym plikiem

### 3. Włącz usługi Firebase

W konsoli Firebase włącz następujące usługi:

#### Authentication
1. Przejdź do Authentication → Sign-in method
2. Włącz "Email/Password"

#### Firestore Database
1. Przejdź do Firestore Database
2. Utwórz bazę danych w trybie testowym
3. Ustaw reguły bezpieczeństwa:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's private streams - only the owner can access
      match /streams/{streamId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Flight tracking data - authenticated users can write, anyone can read
    match /flight_tracking/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Airport data - anyone can read, authenticated users can write
    match /airports/{document} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Aircraft photos - anyone can read, authenticated users can write
    match /aircraft_photos/{photoId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow update: if request.auth != null && request.resource.data.uploadedBy == request.auth.uid;
      allow delete: if request.auth != null && resource.data.uploadedBy == request.auth.uid;
    }
  }
}
```

#### Analytics
1. Analytics jest automatycznie włączony
2. Możesz skonfigurować zdarzenia niestandardowe w sekcji Analytics

#### Crashlytics
1. Przejdź do Crashlytics
2. Włącz dla aplikacji Android

#### Remote Config
1. Przejdź do Remote Config
2. Dodaj parametry konfiguracyjne (opcjonalnie)

#### Firebase Storage
1. Przejdź do Storage
2. Utwórz bucket Storage
3. Ustaw reguły bezpieczeństwa:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Aircraft photos - anyone can read, authenticated users can upload
    match /aircraft_photos/{airportIcao}/{fileName} {
      allow read: if true;
      allow write: if request.auth != null && request.resource.size < 10 * 1024 * 1024; // Max 10MB
      allow delete: if request.auth != null;
    }
  }
}
```

4. **WAŻNE: Skonfiguruj CORS dla Flutter Web**

Aby obrazy działały w aplikacji Flutter Web, musisz skonfigurować CORS dla Firebase Storage:

**Opcja A: Użyj gsutil (zalecane)**

1. Zainstaluj [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. Zaloguj się: `gcloud auth login`
3. Ustaw projekt: `gcloud config set project towerflower-65b92`
4. Utwórz plik `cors.json`:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```
5. Zastosuj konfigurację CORS:
```bash
gsutil cors set cors.json gs://towerflower-65b92.firebasestorage.app
```

**Opcja B: Użyj Firebase Console (prostsze, ale mniej kontroli)**

1. Przejdź do [Google Cloud Console](https://console.cloud.google.com/)
2. Wybierz projekt `towerflower-65b92`
3. Przejdź do **Cloud Storage** → **Buckets**
4. Kliknij na bucket `towerflower-65b92.firebasestorage.app`
5. Przejdź do zakładki **Configuration**
6. W sekcji **CORS** kliknij **Edit**
7. Dodaj konfigurację:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```
8. Zapisz zmiany

**Uwaga**: Dla produkcji zamiast `["*"]` użyj konkretnych domen, np. `["https://twoja-domena.com", "https://www.twoja-domena.com"]`

### 4. Zaktualizuj konfigurację

1. Zastąp dane w `lib/firebase_options.dart` rzeczywistymi danymi z konsoli Firebase
2. Uruchom `flutter pub get`
3. Uruchom `flutter clean && flutter pub get`

### 5. Testowanie

1. Uruchom aplikację
2. Przejdź do ekranu ustawień
3. Spróbuj zarejestrować nowe konto
4. Sprawdź czy dane są zapisywane w Firestore

## Struktura danych w Firestore

### Kolekcja `users`
```json
{
  "favoriteAirport": "EPKK",
  "notificationsEnabled": true,
  "language": "pl",
  "lastUpdated": "timestamp"
}
```

### Kolekcja `flight_tracking`
```json
{
  "icao24": "string",
  "callsign": "string",
  "airport": "string",
  "latitude": "number",
  "longitude": "number",
  "heading": "number",
  "timestamp": "timestamp",
  "userId": "string"
}
```

### Kolekcja `airports`
```json
{
  "icao": "string",
  "name": "string",
  "location": "GeoPoint",
  "liveStreamUrl": "string",
  "lastUpdated": "timestamp"
}
```

### Kolekcja `users/{userId}/streams`
```json
{
  "airportIcao": "string",
  "streamUrl": "string",
  "streamName": "string",
  "createdAt": "timestamp",
  "lastUpdated": "timestamp"
}
```

### Kolekcja `aircraft_photos`
```json
{
  "airportIcao": "string",
  "imageUrl": "string",
  "aircraftRegistration": "string (optional)",
  "flightNumber": "string (optional)",
  "description": "string (optional)",
  "uploadedBy": "string (userId)",
  "uploadedByEmail": "string",
  "uploadedAt": "timestamp",
  "likes": "number"
}
```

## Funkcje zintegrowane z Firebase

- ✅ **Authentication** - logowanie/rejestracja użytkowników
- ✅ **Firestore** - przechowywanie preferencji użytkowników i danych o lotach
- ✅ **Prywatne streamy** - każdy użytkownik może dodać swoje własne linki do streamów
- ✅ **Tymczasowe streamy** - niezalogowani użytkownicy mogą dodawać streamy na czas sesji
- ✅ **Analytics** - śledzenie użycia aplikacji
- ✅ **Crashlytics** - monitorowanie błędów
- ✅ **Remote Config** - dynamiczna konfiguracja (gotowa do użycia)
- ✅ **Storage** - przechowywanie zdjęć samolotów
- ✅ **Zdjęcia samolotów** - przeglądanie (bez logowania), dodawanie (zalogowani)

## Następne kroki

1. Skonfiguruj rzeczywisty projekt Firebase
2. Zastąp pliki konfiguracyjne
3. Przetestuj wszystkie funkcje
4. Rozważ dodanie Firebase Cloud Messaging dla powiadomień push
5. Skonfiguruj Firebase Storage dla przechowywania zdjęć/plików
