# Instrukcja dodania indeksów Firestore

Aplikacja wymaga dwóch złożonych indeksów w Firestore. Masz dwie opcje:

## Opcja 1: Automatyczne (zalecane)

Jeśli masz zainstalowane Firebase CLI:

```bash
firebase deploy --only firestore:indexes
```

## Opcja 2: Ręczne dodanie w konsoli Firebase

1. Przejdź do [Firebase Console](https://console.firebase.google.com/)
2. Wybierz swój projekt
3. Przejdź do **Firestore Database** → **Indexes** (lub **Indeksy**)
4. Kliknij **Add Index** (lub **Dodaj indeks**)

### Indeks 1: Zdjęcia według lotniska
- **Collection ID**: `aircraft_photos`
- **Fields to index**:
  - `airportIcao` - Ascending
  - `uploadedAt` - Descending
- Kliknij **Create** (lub **Utwórz**)

### Indeks 2: Zdjęcia użytkownika
- **Collection ID**: `aircraft_photos`
- **Fields to index**:
  - `uploadedBy` - Ascending
  - `uploadedAt` - Descending
- Kliknij **Create** (lub **Utwórz**)

## Opcja 3: Link bezpośredni z błędu

Gdy aplikacja wyświetli błąd o brakującym indeksie, kliknij link w komunikacie błędu - automatycznie otworzy się strona do utworzenia indeksu.

## Ważne

Indeksy mogą być tworzone przez kilka minut. Po utworzeniu aplikacja automatycznie zacznie ich używać.

