import 'package:latlong2/latlong.dart';

class Airport {
  final String icao;
  final String name;
  final LatLng location;
  final String? liveStreamUrl;

  const Airport({
    required this.icao,
    required this.name,
    required this.location,
    this.liveStreamUrl,
  });

  factory Airport.fromJson(String icao, Map<String, dynamic> json) {
    return Airport(
      icao: icao,
      name: json['name'] ?? 'Nieznane',
      location: LatLng(
        json['latitude'] ?? 0.0,
        json['longitude'] ?? 0.0,
      ),
      liveStreamUrl: json['liveStreamUrl'],
    );
  }
}
