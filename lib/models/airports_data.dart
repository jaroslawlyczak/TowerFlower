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
}

const List<Airport> airports = [
  Airport(
    icao: 'EPKK',
    name: 'Kraków-Balice',
    location: LatLng(50.0777, 19.7848),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPWA',
    name: 'Warszawa-Okęcie',
    location: LatLng(52.1657, 20.9671),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPGD',
    name: 'Gdańsk-Rębiechowo',
    location: LatLng(54.3775, 18.4662),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPPO',
    name: 'Poznań-Ławica',
    location: LatLng(52.4210, 16.8263),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPLL',
    name: 'Łódź-Lublinek',
    location: LatLng(51.7219, 19.3981),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPKT',
    name: 'Katowice-Pyrzowice',
    location: LatLng(50.4742, 19.0806),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPBY',
    name: 'Bydgoszcz-Szwederowo',
    location: LatLng(53.0962, 17.9777),
    liveStreamUrl: null,
  ),
  Airport(
    icao: 'EPSC',
    name: 'Szczecin-Goleniów',
    location: LatLng(53.5846, 14.9027),
    liveStreamUrl: null,
  ),
  Airport(
    icao: 'EPWR',
    name: 'Wrocław-Strachowice',
    location: LatLng(51.1028, 16.8851),
    liveStreamUrl: null, // Brak domyślnego streamu
  ),
  Airport(
    icao: 'EPMO',
    name: 'Warszawa-Modlin',
    location: LatLng(52.4510, 20.6513),
    liveStreamUrl: null,
  ),
  Airport(
    icao: 'EPOK',
    name: 'Olsztyn-Mazury',
    location: LatLng(53.8016, 20.4941),
    liveStreamUrl: null,
  ),
  Airport(
    icao: 'EPRZ',
    name: 'Rzeszów-Jasionka',
    location: LatLng(50.1109, 22.0184),
    liveStreamUrl: null,
  ),
  Airport(
    icao: 'EPRA',
    name: 'Radom-Sadków',
    location: LatLng(51.4027, 21.1479),
    liveStreamUrl: null,
  ),
];

