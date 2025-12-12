enum AircraftCategory {
  small,      // Małe samoloty (np. C172, PA28)
  medium,     // Średnie samoloty (np. B737, A320)
  large,       // Duże samoloty (np. B777, A380)
  helicopter, // Helikoptery (H)
  unknown,    // Nieznany typ
}

class AirportFlight {
  final String? flightNumber;
  final String? airline;
  final String? codesharedNumber;
  final String? aircraft;
  final String? aircraftType; // Kod typu statku (np. "B738", "A320", "H")
  final String? destination;
  final String? origin;
  final DateTime? scheduledTime;
  final DateTime? estimatedTime;
  final DateTime? actualTime;
  final String? status; // "On Time", "Delayed", "Landed", "Departed", etc.
  final String? gate;
  final String? terminal;

  AirportFlight({
    this.flightNumber,
    this.airline,
    this.codesharedNumber,
    this.aircraft,
    this.aircraftType,
    this.destination,
    this.origin,
    this.scheduledTime,
    this.estimatedTime,
    this.actualTime,
    this.status,
    this.gate,
    this.terminal,
  });

  /// Kategoryzuje typ statku powietrznego na podstawie kodu ICAO
  AircraftCategory get category {
    if (aircraftType == null || aircraftType!.isEmpty) {
      return AircraftCategory.unknown;
    }
    
    final type = aircraftType!.toUpperCase();
    
    // Helikoptery
    if (type.startsWith('H') || type.startsWith('Z')) {
      return AircraftCategory.helicopter;
    }
    
    // Małe samoloty (Cessna, Piper, małe regionalne)
    if (type.startsWith('C1') || 
        type.startsWith('C2') || 
        type.startsWith('PA') ||
        type.startsWith('BE') ||
        type.startsWith('SR2') ||
        type.startsWith('AT')) {
      return AircraftCategory.small;
    }
    
    // Duże samoloty (Boeing 777, 787, Airbus A380, A350)
    if (type.startsWith('B77') || 
        type.startsWith('B78') ||
        type.startsWith('A38') ||
        type.startsWith('A35') ||
        type.startsWith('A33')) {
      return AircraftCategory.large;
    }
    
    // Średnie samoloty (Boeing 737, 757, Airbus A320, A321, Embraer)
    // Wszystko inne traktujemy jako średnie
    return AircraftCategory.medium;
  }

  factory AirportFlight.fromArrivalJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          final dt = DateTime.parse(value);
          // Aviationstack zwraca czas oznaczony Z, ale w praktyce jest to czas lokalny portu.
          // Zamiast przesuwać strefę, traktujemy komponenty jako czas lokalny (bez offsetu).
          if (dt.isUtc) {
            return DateTime(
              dt.year,
              dt.month,
              dt.day,
              dt.hour,
              dt.minute,
              dt.second,
              dt.millisecond,
              dt.microsecond,
            );
          }
          return dt;
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    // Aviationstack API struktura
    final flight = json['flight'] as Map<String, dynamic>?;
    final airline = json['airline'] as Map<String, dynamic>?;
    final codeshared = json['codeshared'] as Map<String, dynamic>?;
    final codesharedFlight = codeshared?['flight'] as Map<String, dynamic>?;
    final codesharedAirline = codeshared?['airline'] as Map<String, dynamic>?;
    final departure = json['departure'] as Map<String, dynamic>?;
    final arrival = json['arrival'] as Map<String, dynamic>?;
    final aircraft = json['aircraft'] as Map<String, dynamic>?;

    String? resolveFlightNumber() {
      // Prefer numer operującego lotu z codeshared, potem własny flight, na końcu ogólny number.
      return codesharedFlight?['iata'] ??
          codesharedFlight?['icao'] ??
          codesharedFlight?['number'] ??
          flight?['iata'] ??
          flight?['icao'] ??
          flight?['number'];
    }

    String? resolveAirline() {
      return codesharedAirline?['name'] ??
          codesharedAirline?['iata'] ??
          codesharedAirline?['icao'] ??
          airline?['name'] ??
          airline?['iata'] ??
          airline?['icao'];
    }

    return AirportFlight(
      flightNumber: resolveFlightNumber(),
      airline: resolveAirline(),
      codesharedNumber: codesharedFlight?['iata'] ?? codesharedFlight?['icao'] ?? codesharedFlight?['number'],
      aircraft: aircraft?['iata'] ?? aircraft?['icao'] ?? aircraft?['registration'],
      aircraftType: aircraft?['icao'] ?? aircraft?['iata'], // Kod typu statku (np. "B738", "A320")
      destination: arrival?['iata'] ?? arrival?['icao'] ?? arrival?['airport'],
      origin: departure?['iata'] ?? departure?['icao'] ?? departure?['airport'],
      scheduledTime: parseDateTime(arrival?['scheduled']),
      estimatedTime: parseDateTime(arrival?['estimated']),
      actualTime: parseDateTime(arrival?['actual']),
      status: json['flight_status'] ?? 'Unknown',
      gate: arrival?['gate'] ?? departure?['gate'],
      terminal: arrival?['terminal'] ?? departure?['terminal'],
    );
  }

  factory AirportFlight.fromDepartureJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        try {
          final dt = DateTime.parse(value);
          if (dt.isUtc) {
            return DateTime(
              dt.year,
              dt.month,
              dt.day,
              dt.hour,
              dt.minute,
              dt.second,
              dt.millisecond,
              dt.microsecond,
            );
          }
          return dt;
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    final flight = json['flight'] as Map<String, dynamic>?;
    final airline = json['airline'] as Map<String, dynamic>?;
    final codeshared = json['codeshared'] as Map<String, dynamic>?;
    final codesharedFlight = codeshared?['flight'] as Map<String, dynamic>?;
    final codesharedAirline = codeshared?['airline'] as Map<String, dynamic>?;
    final departure = json['departure'] as Map<String, dynamic>?;
    final arrival = json['arrival'] as Map<String, dynamic>?;
    final aircraft = json['aircraft'] as Map<String, dynamic>?;

    String? resolveFlightNumber() {
      return codesharedFlight?['iata'] ??
          codesharedFlight?['icao'] ??
          codesharedFlight?['number'] ??
          flight?['iata'] ??
          flight?['icao'] ??
          flight?['number'];
    }

    String? resolveAirline() {
      return codesharedAirline?['name'] ??
          codesharedAirline?['iata'] ??
          codesharedAirline?['icao'] ??
          airline?['name'] ??
          airline?['iata'] ??
          airline?['icao'];
    }

    return AirportFlight(
      flightNumber: resolveFlightNumber(),
      airline: resolveAirline(),
      codesharedNumber: codesharedFlight?['iata'] ?? codesharedFlight?['icao'] ?? codesharedFlight?['number'],
      aircraft: aircraft?['iata'] ?? aircraft?['icao'] ?? aircraft?['registration'],
      aircraftType: aircraft?['icao'] ?? aircraft?['iata'], // Kod typu statku (np. "B738", "A320")
      destination: arrival?['iata'] ?? arrival?['icao'] ?? arrival?['airport'],
      origin: departure?['iata'] ?? departure?['icao'] ?? departure?['airport'],
      scheduledTime: parseDateTime(departure?['scheduled']),
      estimatedTime: parseDateTime(departure?['estimated']),
      actualTime: parseDateTime(departure?['actual']),
      status: json['flight_status'] ?? 'Unknown',
      gate: arrival?['gate'] ?? departure?['gate'],
      terminal: arrival?['terminal'] ?? departure?['terminal'],
    );
  }
}

