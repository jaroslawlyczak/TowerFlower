class Flight {
  final String icao24;
  final String callsign;
  final double latitude;
  final double longitude;
  final double heading;
  final double velocity;
  final double altitude;
  final bool onGround;
  final String originCountry;

  Flight({
    required this.icao24,
    required this.callsign,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.velocity,
    required this.altitude,
    required this.onGround,
    required this.originCountry,
  });

  factory Flight.fromJson(List<dynamic> state) {
    return Flight(
      icao24: state[0],
      callsign: (state[1] ?? 'Brak').toString().trim(),
      originCountry: state[2] ?? 'Nieznany',
      longitude: (state[5] ?? 0.0).toDouble(),
      latitude: (state[6] ?? 0.0).toDouble(),
      heading: (state[10] ?? 0.0).toDouble(),
      velocity: (state[9] ?? 0.0).toDouble(),
      altitude: (state[13] ?? state[7] ?? 0.0).toDouble(), // geo lub baro
      onGround: state[8] ?? false,
    );
  }
}
