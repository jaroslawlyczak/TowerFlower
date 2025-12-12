import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../models/fligth.dart';

class OpenSkyService {
  static const String _baseUrl = 'https://opensky-network.org/api';

  Future<List<Flight>> fetchFlights({
    required double lamin,
    required double lomin,
    required double lamax,
    required double lomax,
  }) async {
    final url = Uri.parse(
        '$_baseUrl/states/all?lamin=$lamin&lomin=$lomin&lamax=$lamax&lomax=$lomax');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania lotów');
    }

    final data = json.decode(response.body);
    final states = data['states'] as List<dynamic>? ?? [];

    return states.map((state) => Flight.fromJson(state)).toList();
  }

  Future<List<LatLng>> fetchFlightTrack(String icao24) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final url = Uri.parse('$_baseUrl/tracks/all?icao24=$icao24&time=$timestamp');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> track = data['path'] ?? [];
      return track.map<LatLng>((coord) => LatLng(coord[1], coord[2])).toList();
    } else {
      throw Exception('Nie udało się pobrać śladu lotu dla $icao24');
    }
  }
}
