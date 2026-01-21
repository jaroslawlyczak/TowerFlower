import 'airport_flight.dart'; // Import AircraftCategory

class Aircraft {
  final String icao24;
  final String callsign;
  final String originCountry;
  final double longitude;
  final double latitude;
  final double altitude;
  final double velocity;
  final double heading;
  final String departureIcao;
  final String arrivalIcao;
  final String? aircraftType; // Kod typu statku (np. "B738", "A320", "H")

  Aircraft({
    required this.icao24,
    required this.callsign,
    required this.originCountry,
    required this.longitude,
    required this.latitude,
    required this.altitude,
    required this.velocity,
    required this.heading,
    required this.departureIcao,
    required this.arrivalIcao,
    this.aircraftType,
  });

  /// Kategoryzuje typ statku powietrznego na podstawie kodu ICAO
  /// Zwraca unknown jeśli brak typu statku (API nie pozwala na przewidywanie)
  AircraftCategory get category {
    // Jeśli mamy kod typu statku, użyj go
    if (aircraftType != null && aircraftType!.isNotEmpty) {
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
      return AircraftCategory.medium;
    }
    
    // Brak typu statku - zwróć unknown (API nie pozwala na przewidywanie)
    return AircraftCategory.unknown;
  }


  factory Aircraft.fromFlightJson(Map<String, dynamic> json) {
    return Aircraft(
      icao24: json['icao24'] ?? '',
      callsign: json['callsign']?.toString().trim() ?? '',
      originCountry: json['origin_country'] ?? '',
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      velocity: (json['velocity'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      departureIcao: json['departure_icao'] ?? '',
      arrivalIcao: json['arrival_icao'] ?? '',
      aircraftType: json['t'] ?? json['aircraft_type'], // Typ statku jeśli dostępny
    );
  }


  factory Aircraft.fromJson(List<dynamic> json) {
    return Aircraft(
      icao24: json[0] ?? '',
      callsign: json[1]?.toString().trim() ?? '',
      originCountry: json[2] ?? '',
      longitude: (json[5] as num?)?.toDouble() ?? 0.0,
      latitude: (json[6] as num?)?.toDouble() ?? 0.0,
      altitude: (json[7] as num?)?.toDouble() ?? 0.0,
      velocity: (json[9] as num?)?.toDouble() ?? 0.0,
      heading: (json[10] as num?)?.toDouble() ?? 0.0,
      departureIcao: json.length > 18 ? (json[18] ?? '') : '',
      arrivalIcao: json.length > 19 ? (json[19] ?? '') : '',
      aircraftType: null, // OpenSky nie zwraca typu statku
    );
  }
}
