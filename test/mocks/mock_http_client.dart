/// Mock HTTP Client dla testów
class MockHttpClient {

  /// Konfiguruje mock odpowiedzi dla OpenSky API
  static void setupMocks() {
    // Mock setup - w przyszłości można dodać rzeczywiste mockowanie HTTP
  }

  /// Przywraca oryginalny klient HTTP
  static void teardownMocks() {
    // Mock teardown
  }

  /// Mock odpowiedź dla OpenSky states API
  static Map<String, dynamic> getMockStatesResponse() {
    return {
      'time': 1234567890,
      'states': [
        [
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
        ],
      ],
    };
  }

  /// Mock odpowiedź dla OpenSky tracks API
  static Map<String, dynamic> getMockTracksResponse() {
    return {
      'icao24': 'abc123',
      'callsign': 'TEST01',
      'startTime': 1234567890,
      'endTime': 1234567900,
      'path': [
        [1234567890, 52.2297, 21.0122],
        [1234567895, 52.2300, 21.0125],
      ],
    };
  }
}
