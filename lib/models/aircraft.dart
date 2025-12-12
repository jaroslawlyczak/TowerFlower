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

  /// Kategoryzuje typ statku powietrznego na podstawie kodu ICAO lub heurystyki
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
    
    // Heurystyka na podstawie callsign i innych danych (gdy nie mamy typu statku)
    return _detectCategoryFromHeuristics();
  }

  /// Wykrywa kategorię statku na podstawie heurystyki (callsign, prędkość, wysokość)
  AircraftCategory _detectCategoryFromHeuristics() {
    final callsignUpper = callsign.toUpperCase();
    
    // Wykrywanie helikopterów na podstawie callsign
    // Helikoptery często mają prefiksy: HELI, RESCUE, POLICE, MED, SAR, HEMS, etc.
    if (callsignUpper.contains('HELI') ||
        callsignUpper.contains('RESCUE') ||
        callsignUpper.contains('POLICE') ||
        callsignUpper.contains('MED') ||
        callsignUpper.contains('SAR') ||
        callsignUpper.contains('HEMS') ||
        callsignUpper.contains('AIR') && callsignUpper.contains('AMB') ||
        callsignUpper.startsWith('H') && callsignUpper.length <= 4) {
      return AircraftCategory.helicopter;
    }
    
    // Wykrywanie helikopterów na podstawie prędkości i wysokości
    // Helikoptery zwykle latają wolniej (< 200 km/h) i na niższych wysokościach
    if (velocity > 0 && velocity < 55 && altitude < 3000) {
      // Może być helikopter, ale nie jesteśmy pewni - zostaw jako unknown
    }
    
    // Wykrywanie małych samolotów na podstawie callsign
    // Małe samoloty często mają krótkie callsigny lub zaczynają się od liter C, N (USA)
    if (callsignUpper.length <= 4 && 
        (callsignUpper.startsWith('C') || 
         callsignUpper.startsWith('N') ||
         callsignUpper.startsWith('G'))) {
      // Może być mały samolot, ale nie jesteśmy pewni
    }
    
    // Wykrywanie dużych samolotów na podstawie callsign
    // Duże samoloty komercyjne mają callsigny linii lotniczych (3-4 litery + numery)
    // np. LOT, LH, BA, FR, etc.
    if (callsignUpper.length >= 5 && 
        callsignUpper.length <= 7 &&
        RegExp(r'^[A-Z]{2,3}\d{1,4}$').hasMatch(callsignUpper)) {
      // Może być średni/duży samolot komercyjny
      // Sprawdź prędkość - duże samoloty latają szybciej
      if (velocity > 200) {
        return AircraftCategory.large;
      }
      return AircraftCategory.medium;
    }
    
    // Domyślnie traktuj jako średni samolot (najczęstszy przypadek)
    return AircraftCategory.medium;
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
