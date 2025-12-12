import 'package:latlong2/latlong.dart';
import '../services/firebase_service.dart';
import 'airport.dart';

/// Domyślna lista lotnisk (fallback)
const List<Airport> defaultAirports = [
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

/// Lista lotnisk używana w aplikacji (może być nadpisana przez Firebase)
List<Airport> airports = defaultAirports;

/// Ładuje lotniska z Firebase lub używa domyślnej listy
Future<List<Airport>> loadAirports() async {
  try {
    final firebaseService = FirebaseService();
    final firebaseAirports = await firebaseService.getAirports();
    
    if (firebaseAirports.isNotEmpty) {
      // Połącz lotniska z Firebase z domyślnymi (bez duplikatów)
      final icaoCodes = firebaseAirports.map((a) => a.icao).toSet();
      final additionalDefaults = defaultAirports.where((a) => !icaoCodes.contains(a.icao)).toList();
      
      airports = [...firebaseAirports, ...additionalDefaults];
      return airports;
    } else {
      airports = defaultAirports;
      return airports;
    }
  } catch (e) {
    // W przypadku błędu użyj domyślnej listy
    airports = defaultAirports;
    return airports;
  }
}

