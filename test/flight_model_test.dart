import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/models/fligth.dart';

void main() {
  group('Flight Model Tests', () {
    test('should create Flight from JSON correctly', () {
      // Sample OpenSky API state data
      final stateData = [
        'abc123', // icao24
        'TEST01', // callsign
        'Poland', // originCountry
        null, // timePosition
        null, // lastContact
        52.2297, // longitude
        21.0122, // latitude
        null, // baroAltitude
        false, // onGround
        250.0, // velocity
        0.0, // trueTrack
        45.0, // heading
        0.0, // verticalRate
        10000.0, // geoAltitude
      ];

      final flight = Flight.fromJson(stateData);

      expect(flight.icao24, 'abc123');
      expect(flight.callsign, 'TEST01');
      expect(flight.originCountry, 'Poland');
      expect(flight.longitude, 52.2297);
      expect(flight.latitude, 21.0122);
      expect(flight.heading, 45.0);
      expect(flight.velocity, 250.0);
      expect(flight.onGround, false);
    });

    test('should handle missing optional fields', () {
      final stateData = [
        'abc123',
        null, // callsign missing
        null, // originCountry missing
        null,
        null,
        0.0, // longitude
        0.0, // latitude
        null,
        null, // onGround missing
        0.0,
        0.0,
        null, // heading missing
        0.0,
        null, // geoAltitude missing
      ];

      final flight = Flight.fromJson(stateData);

      expect(flight.callsign, 'Brak');
      expect(flight.originCountry, 'Nieznany');
      expect(flight.heading, 0.0);
      expect(flight.altitude, 0.0);
    });
  });
}

