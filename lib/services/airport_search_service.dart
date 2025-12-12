import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/airport.dart';

/// Serwis do wyszukiwania lotnisk z różnych źródeł
class AirportSearchService {
  /// Wyszukuje lotnisko po kodzie ICAO
  /// Próbuje różnych źródeł danych
  Future<Airport?> searchAirportByIcao(String icao) async {
    if (icao.isEmpty || icao.length != 4) {
      return null;
    }

    // Próba 1: OpenSky Network API (jeśli dostępne)
    try {
      final airport = await _searchFromOpenSky(icao);
      if (airport != null) return airport;
    } catch (e) {
      // Ignoruj błędy, próbuj dalej
    }

    // Próba 2: AviationStack API (jeśli dostępne)
    try {
      final airport = await _searchFromAviationStack(icao);
      if (airport != null) return airport;
    } catch (e) {
      // Ignoruj błędy
    }

    // Próba 3: Publiczna baza danych lotnisk (OurAirports)
    try {
      final airport = await _searchFromOurAirports(icao);
      if (airport != null) return airport;
    } catch (e) {
      // Ignoruj błędy
    }

    return null;
  }

  /// Wyszukuje lotnisko z OpenSky Network API
  Future<Airport?> _searchFromOpenSky(String icao) async {
    // OpenSky Network nie ma bezpośredniego API do lotnisk,
    // ale możemy użyć innych źródeł
    return null;
  }

  /// Wyszukuje lotnisko z AviationStack API
  Future<Airport?> _searchFromAviationStack(String icao) async {
    // AviationStack wymaga klucza API, więc pomijamy na razie
    return null;
  }

  /// Wyszukuje lotnisko z OurAirports (publiczna baza danych)
  Future<Airport?> _searchFromOurAirports(String icao) async {
    try {
      // OurAirports ma publiczną bazę danych lotnisk
      // Pobieramy dane z ich API
      final url = Uri.parse(
        'https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/airports.csv',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        
        // Pomijamy nagłówek
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i];
          final parts = line.split(',');
          
          // Format CSV: id,ident,type,name,latitude_deg,longitude_deg,...
          if (parts.length >= 6) {
            final ident = parts[1].replaceAll('"', '');
            if (ident.toUpperCase() == icao.toUpperCase()) {
              final name = parts[3].replaceAll('"', '');
              final latStr = parts[4].replaceAll('"', '');
              final lonStr = parts[5].replaceAll('"', '');
              
              final lat = double.tryParse(latStr);
              final lon = double.tryParse(lonStr);
              
              if (lat != null && lon != null && lat != 0 && lon != 0) {
                return Airport(
                  icao: icao.toUpperCase(),
                  name: name.isNotEmpty ? name : 'Lotnisko $icao',
                  location: LatLng(lat, lon),
                  liveStreamUrl: null,
                );
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignoruj błędy
    }
    return null;
  }

  /// Wyszukuje lotniska po nazwie (przybliżone wyszukiwanie)
  Future<List<Airport>> searchAirportsByName(String query) async {
    if (query.isEmpty || query.length < 2) {
      return [];
    }

    final results = <Airport>[];
    
    try {
      // Używamy OurAirports do wyszukiwania po nazwie
      final url = Uri.parse(
        'https://raw.githubusercontent.com/davidmegginson/ourairports-data/main/airports.csv',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final lines = const LineSplitter().convert(response.body);
        final queryLower = query.toLowerCase();
        
        // Pomijamy nagłówek i ograniczamy do pierwszych 50 wyników
        int count = 0;
        for (int i = 1; i < lines.length && count < 50; i++) {
          final line = lines[i];
          final parts = line.split(',');
          
          if (parts.length >= 6) {
            final ident = parts[1].replaceAll('"', '').toUpperCase();
            final name = parts[3].replaceAll('"', '').toLowerCase();
            
            // Sprawdź czy nazwa lub kod zawiera zapytanie
            if (name.contains(queryLower) || ident.contains(query.toUpperCase())) {
              final latStr = parts[4].replaceAll('"', '');
              final lonStr = parts[5].replaceAll('"', '');
              
              final lat = double.tryParse(latStr);
              final lon = double.tryParse(lonStr);
              
              // Tylko lotniska z kodami ICAO (4 znaki) i ważnymi współrzędnymi
              if (ident.length == 4 && lat != null && lon != null && lat != 0 && lon != 0) {
                results.add(Airport(
                  icao: ident,
                  name: parts[3].replaceAll('"', ''),
                  location: LatLng(lat, lon),
                  liveStreamUrl: null,
                ));
                count++;
              }
            }
          }
        }
      }
    } catch (e) {
      // Ignoruj błędy
    }
    
    return results;
  }
}

