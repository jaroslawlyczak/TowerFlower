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
  });


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
    );
  }
}
