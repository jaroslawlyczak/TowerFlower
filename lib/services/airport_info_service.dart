import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/airport_flight.dart';

class AirportInfoService {
  // Aviationstack API
  static const String _baseUrl = 'https://api.aviationstack.com/v1';
  // Domyślny klucz API użytkownika - ustaw przez zmienną środowiskową lub setApiKey()
  // UWAGA: Przed użyciem ustaw klucz API przez setApiKey() lub konstruktor
  static const String _defaultApiKey = 'SET_YOUR_API_KEY_HERE'; // Placeholder - wymaga ustawienia
  String _apiKey;
  // Instrumentation removed after fix confirmation
  void _agentLog({
    required String location,
    required String message,
    required Map<String, dynamic> data,
    required String hypothesisId,
    String runId = 'post-fix',
  }) {
    // no-op
  }

  AirportInfoService({String? apiKey}) : _apiKey = apiKey ?? _defaultApiKey;

  // Metoda do ustawienia klucza API (można przechowywać w ustawieniach)
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Pobiera przyloty dla danego lotniska (ICAO)
  /// [hoursRange] - zakres godzin do przefiltrowania (domyślnie 1 godzina)
  Future<List<AirportFlight>> fetchArrivals(String airportIcao, {int hoursRange = 1}) async {
    if (_apiKey.isEmpty || _apiKey == 'SET_YOUR_API_KEY_HERE') {
      throw Exception('API key nie jest ustawiony. Ustaw klucz przez setApiKey() lub konstruktor AirportInfoService(apiKey: "TWÓJ_KLUCZ").');
    }

    try {
      // Aviationstack API - przyloty
      // Uwaga: flight_date może nie być dostępne w darmowym planie, więc filtrujemy po stronie klienta
      final url = Uri.parse(
        '$_baseUrl/flights?access_key=$_apiKey&arr_icao=$airportIcao&limit=100',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Sprawdź czy jest błąd w odpowiedzi
        if (data.containsKey('error')) {
          final error = data['error'];
          throw Exception('${error['message'] ?? 'Błąd API'} (${error['code'] ?? 'unknown'})');
        }
        
        final List<dynamic> flights = data['data'] ?? [];
        // Surowe próbki czasów z API (przed parsowaniem)
        final allFlights = flights.map((json) => AirportFlight.fromArrivalJson(json as Map<String, dynamic>)).toList();
        
        // Jeśli brak lotów, zwróć pustą listę
        if (allFlights.isEmpty) {
          return [];
        }
        
        // Filtruj loty według lokalnego czasu urządzenia: od -30 min do +X godzin
        final nowLocal = DateTime.now();
        // Umiarkowany bufor: -30 min wstecz, +X h + 60 min do przodu
        final startTimeLocal = nowLocal.subtract(const Duration(minutes: 30));
        final endTimeLocal = nowLocal.add(Duration(hours: hoursRange, minutes: 60));
        
        final filtered = allFlights.where((flight) {
          // Użyj actualTime jeśli dostępne, w przeciwnym razie scheduled lub estimated
          DateTime? flightTimeLocal;
          
          if (flight.actualTime != null) {
            flightTimeLocal = flight.actualTime!;
          } else {
            final scheduledTime = flight.scheduledTime ?? flight.estimatedTime;
            if (scheduledTime == null) {
              return false;
            }
            flightTimeLocal = scheduledTime;
          }
          
          // Sprawdź czy lot jest w zakresie czasowym (lokalnie od -30 min do +X godzin)
          final inRange = (flightTimeLocal.isAfter(startTimeLocal) || flightTimeLocal.isAtSameMomentAs(startTimeLocal)) && 
                         (flightTimeLocal.isBefore(endTimeLocal) || flightTimeLocal.isAtSameMomentAs(endTimeLocal));
          
          return inRange;
        }).toList();
        
        
        // Zwróć przefiltrowane loty
        return filtered
          ..sort((a, b) {
            final timeA = a.scheduledTime ?? a.estimatedTime ?? a.actualTime ?? DateTime.now();
            final timeB = b.scheduledTime ?? b.estimatedTime ?? b.actualTime ?? DateTime.now();
            return timeA.compareTo(timeB);
          });
      } else if (response.statusCode == 401) {
        throw Exception('Nieprawidłowy klucz API');
      } else if (response.statusCode == 429) {
        throw Exception('Przekroczono limit zapytań do API. Spróbuj ponownie za chwilę.');
      } else {
        throw Exception('Błąd pobierania danych: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('429')) {
        rethrow;
      }
      throw Exception('Błąd pobierania przylotów: $e');
    }
  }

  /// Pobiera odloty dla danego lotniska (ICAO)
  /// [hoursRange] - zakres godzin do przefiltrowania (domyślnie 1 godzina)
  Future<List<AirportFlight>> fetchDepartures(String airportIcao, {int hoursRange = 1}) async {
    if (_apiKey.isEmpty || _apiKey == 'SET_YOUR_API_KEY_HERE') {
      throw Exception('API key nie jest ustawiony. Ustaw klucz przez setApiKey() lub konstruktor AirportInfoService(apiKey: "TWÓJ_KLUCZ").');
    }

    try {
      // Aviationstack API - odloty
      // Uwaga: flight_date może nie być dostępne w darmowym planie, więc filtrujemy po stronie klienta
      final url = Uri.parse(
        '$_baseUrl/flights?access_key=$_apiKey&dep_icao=$airportIcao&limit=100',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Sprawdź czy jest błąd w odpowiedzi
        if (data.containsKey('error')) {
          final error = data['error'];
          throw Exception('${error['message'] ?? 'Błąd API'} (${error['code'] ?? 'unknown'})');
        }
        
        final List<dynamic> flights = data['data'] ?? [];
        final allFlights = flights.map((json) => AirportFlight.fromDepartureJson(json as Map<String, dynamic>)).toList();
        
        // Jeśli brak lotów, zwróć pustą listę
        if (allFlights.isEmpty) {
          return [];
        }
        
        // Filtruj loty według lokalnego czasu urządzenia (od -30 min do +X godzin)
        final nowLocal = DateTime.now();
        // Umiarkowany bufor: -30 min wstecz, +X h + 60 min do przodu
        final startTimeLocal = nowLocal.subtract(const Duration(minutes: 30)); // 30 minut wstecz
        final endTimeLocal = nowLocal.add(Duration(hours: hoursRange, minutes: 60)); // X godzin + 60 min
        
        final filtered = allFlights.where((flight) {
          // Użyj actualTime jeśli dostępne, w przeciwnym razie scheduled lub estimated
          DateTime? flightTimeLocal;
          
          if (flight.actualTime != null) {
            flightTimeLocal = flight.actualTime!;
          } else {
            final scheduledTime = flight.scheduledTime ?? flight.estimatedTime;
            if (scheduledTime == null) {
              return false;
            }
            flightTimeLocal = scheduledTime;
          }
          
          // Sprawdź czy lot jest w zakresie czasowym (lokalnie od -30 min do +X godzin)
          final inRange = (flightTimeLocal.isAfter(startTimeLocal) || flightTimeLocal.isAtSameMomentAs(startTimeLocal)) && 
                         (flightTimeLocal.isBefore(endTimeLocal) || flightTimeLocal.isAtSameMomentAs(endTimeLocal));
          
          return inRange;
        }).toList();
        if (allFlights.isNotEmpty) {
          final sample = allFlights.take(2).map((f) {
            final s = f.scheduledTime;
            final e = f.estimatedTime;
            return {
              'flight': f.flightNumber,
              'scheduled': s?.toIso8601String(),
              'scheduledIsUtc': s?.isUtc,
              'estimated': e?.toIso8601String(),
              'estimatedIsUtc': e?.isUtc,
            };
          }).toList();
          _agentLog(
            location: 'airport_info_service.dart:fetchDepartures',
            message: 'Sample departure times',
            data: {'sample': sample},
            hypothesisId: 'H3',
            runId: 'post-fix',
          );
        }
        
        _agentLog(
          location: 'airport_info_service.dart:fetchDepartures',
          message: 'Departures filter stats',
          data: {
            'filtered': filtered.length,
            'total': allFlights.length,
          },
          hypothesisId: 'H1',
          runId: 'post-fix',
        );
        if (filtered.isNotEmpty) {
          final sampleFiltered = filtered.take(5).map((f) {
            final t = f.scheduledTime ?? f.estimatedTime ?? f.actualTime;
            return {
              'flight': f.flightNumber,
              'status': f.status,
              'time': t?.toIso8601String(),
              'isUtc': t?.isUtc,
              'local': t?.toIso8601String(),
            };
          }).toList();
          _agentLog(
            location: 'airport_info_service.dart:fetchDepartures',
            message: 'Departures filtered sample',
            data: {'sample': sampleFiltered},
            hypothesisId: 'H4',
            runId: 'post-fix',
          );
          final times = filtered
              .map((f) => f.actualTime ?? f.estimatedTime ?? f.scheduledTime)
              .whereType<DateTime>()
              .toList()
            ..sort();
          if (times.isNotEmpty) {
            _agentLog(
              location: 'airport_info_service.dart:fetchDepartures',
              message: 'Departures min/max times',
              data: {
                'min': times.first.toIso8601String(),
                'max': times.last.toIso8601String(),
              },
              hypothesisId: 'H5',
              runId: 'post-fix',
            );
          }
        }
        
        // Zwróć przefiltrowane loty
        return filtered
          ..sort((a, b) {
            final timeA = a.scheduledTime ?? a.estimatedTime ?? a.actualTime ?? DateTime.now();
            final timeB = b.scheduledTime ?? b.estimatedTime ?? b.actualTime ?? DateTime.now();
            return timeA.compareTo(timeB);
          });
      } else if (response.statusCode == 401) {
        throw Exception('Nieprawidłowy klucz API');
      } else if (response.statusCode == 429) {
        throw Exception('Przekroczono limit zapytań do API. Spróbuj ponownie za chwilę.');
      } else {
        throw Exception('Błąd pobierania danych: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('429')) {
        rethrow;
      }
      throw Exception('Błąd pobierania odlotów: $e');
    }
  }

  /// Alternatywna metoda dla RapidAPI (przykład z FlightLabs API)
  Future<List<AirportFlight>> fetchArrivalsRapidAPI(String airportIcao, String rapidApiKey) async {
    try {
      final url = Uri.parse(
        'https://flightlabs.p.rapidapi.com/airports?iataCode=$airportIcao',
      );

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': rapidApiKey,
          'X-RapidAPI-Host': 'flightlabs.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> arrivals = data['data']?['arrivals'] ?? [];
        return arrivals.map((json) => AirportFlight.fromArrivalJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Błąd pobierania danych: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd pobierania przylotów: $e');
    }
  }

  Future<List<AirportFlight>> fetchDeparturesRapidAPI(String airportIcao, String rapidApiKey) async {
    try {
      final url = Uri.parse(
        'https://flightlabs.p.rapidapi.com/airports?iataCode=$airportIcao',
      );

      final response = await http.get(
        url,
        headers: {
          'X-RapidAPI-Key': rapidApiKey,
          'X-RapidAPI-Host': 'flightlabs.p.rapidapi.com',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> departures = data['data']?['departures'] ?? [];
        return departures.map((json) => AirportFlight.fromDepartureJson(json as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Błąd pobierania danych: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Błąd pobierania odlotów: $e');
    }
  }
}

