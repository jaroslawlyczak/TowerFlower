// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:collection/collection.dart'; // <<<<<< tutaj!

import '../models/airports_data.dart';
import '../services/firebase_service.dart';
import 'flights_board_screen.dart';
import 'settings_screen.dart';
import 'streams_management_screen.dart';
import 'airport_info_screen.dart';
import 'aircraft_photos_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapLayerConfig {
  final String name;
  final String urlTemplate;
  final List<String> subdomains;

  const _MapLayerConfig({
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
  });
}

class _MapScreenState extends State<MapScreen> {
  final List<Marker> _aircraftMarkers = [];
  final List<Polyline> _flightPaths = [];
  String _selectedIcao = '';
  String? _listeningIcao;
  String? _currentStreamName;
  String? _currentStreamUrl;
  bool _isPlaying = false;
  List<Map<String, dynamic>> _userStreams = [];
  
  // Live tracking state
  String? _trackedIcao24;
  String? _trackedCallsign; // Przechowuj callsign dla łatwej identyfikacji
  int? _trackedMarkerIndex; // Indeks markera śledzonego samolotu w liście
  Timer? _liveTrackingTimer;
  Timer? _apiRefreshTimer;
  LatLng? _lastKnownPosition;
  double? _lastKnownHeading;
  double? _lastKnownVelocity;
  List<LatLng> _trackedFlightPath = []; // Postępująca trasa śledzonego samolotu
  List<LatLng> _historicalFlightPath = []; // Stara trasa (z API tracks)

  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseService _firebaseService = FirebaseService();
  final List<_MapLayerConfig> _mapLayers = const [
    _MapLayerConfig(
      name: 'OSM Standard',
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    ),
    _MapLayerConfig(
      name: 'OSM HOT',
      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
    ),
    _MapLayerConfig(
      name: 'Topo',
      urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
      subdomains: ['a', 'b', 'c'],
    ),
  ];
  int _currentLayerIndex = 0;

  Airport? get _selectedAirport =>
      airports.firstWhereOrNull((a) => a.icao == _selectedIcao);

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadUserStreams();
  }

  Future<void> _loadUserStreams() async {
    try {
      final streams = await _firebaseService.getAllUserStreams();
      setState(() {
        _userStreams = streams;
      });
    } catch (e) {
      print('Błąd ładowania streamów użytkownika: $e');
    }
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      print('AudioPlayer state changed: playing=${state.playing}, processingState=${state.processingState}, listeningIcao=$_listeningIcao');
      setState(() {
        _isPlaying = state.playing;
        // Resetuj stan tylko jeśli stream został zatrzymany i nie ma ustawionego listeningIcao
        // To oznacza, że użytkownik zatrzymał stream ręcznie, a nie przełącza go
        if (!state.playing && _listeningIcao != null) {
          // Sprawdź czy to nie jest przejściowy stan podczas przełączania
          // Resetuj tylko jeśli processingState wskazuje na zatrzymanie i nie ma nowego streamu do odtworzenia
          if (state.processingState == ProcessingState.idle || 
              state.processingState == ProcessingState.completed) {
            // Nie resetuj jeśli _isPlaying jest true (oznacza to że nowy stream się ładuje)
            // lub jeśli _currentStreamUrl jest ustawiony (nowy stream jest gotowy)
            if (!_isPlaying && _currentStreamUrl == null) {
              _listeningIcao = null;
              _currentStreamName = null;
              _currentStreamUrl = null;
            }
          }
        }
      });
    });

    // Obsługa błędów - ignoruj przejściowe błędy podczas inicjalizacji
    _audioPlayer.playbackEventStream.listen((event) {
      // Ignoruj przejściowe błędy podczas ładowania streamu
    }, onError: (error) {
      print('AudioPlayer error: $error');
      // Nie pokazuj powiadomienia jeśli stream się odtwarza
      if (!_isPlaying) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd streamu: $error'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _stopLiveTracking();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _stopLiveTracking() {
    _liveTrackingTimer?.cancel();
    _apiRefreshTimer?.cancel();
    _liveTrackingTimer = null;
    _apiRefreshTimer = null;
    _trackedIcao24 = null;
    _trackedCallsign = null;
    _trackedMarkerIndex = null;
    _lastKnownPosition = null;
    _lastKnownHeading = null;
    _lastKnownVelocity = null;
    _trackedFlightPath.clear();
    _historicalFlightPath.clear();
    setState(() {
      _flightPaths.clear();
    });
  }
  
  void _startLiveTracking({
    required String icao24,
    required double initialLat,
    required double initialLon,
    required double initialHeading,
    String? callsign,
    int? markerIndex,
  }) async {
    // Zatrzymaj poprzednie śledzenie jeśli było aktywne (ale zachowaj podstawowe dane)
    _liveTrackingTimer?.cancel();
    _apiRefreshTimer?.cancel();
    _liveTrackingTimer = null;
    _apiRefreshTimer = null;
    _trackedFlightPath.clear();
    _historicalFlightPath.clear();
    
    // Ustaw dane śledzenia (nie resetuj jeśli już są ustawione z fetchAircraftPositions)
    _trackedIcao24 = icao24;
    _trackedCallsign = callsign ?? _trackedCallsign;
    _trackedMarkerIndex = markerIndex ?? _trackedMarkerIndex; // Zapamiętaj indeks markera
    _lastKnownPosition = LatLng(initialLat, initialLon);
    _lastKnownHeading = initialHeading;
    _trackedFlightPath = [LatLng(initialLat, initialLon)]; // Rozpocznij nową trasę
    
    // Pobierz starą trasę z API
    final historicalTrack = await fetchFlightTrack(icao24);
    _historicalFlightPath = historicalTrack;
    
    // Wyświetl starą trasę
    setState(() {
      _flightPaths.clear();
      if (_historicalFlightPath.isNotEmpty) {
        _flightPaths.add(Polyline(
          points: _historicalFlightPath,
          color: Colors.orange,
          strokeWidth: 2.5,
        ));
      }
    });
    
    // API refresh every 45 seconds (conservative)
    _apiRefreshTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _refreshTrackedAircraftPosition();
    });
    
    // Interpolation update every 3 seconds
    _liveTrackingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateAircraftPositionInterpolation();
    });
    
    // Initial API refresh
    _refreshTrackedAircraftPosition();
  }
  
  Future<void> _refreshTrackedAircraftPosition() async {
    if (_trackedIcao24 == null || _selectedIcao.isEmpty) return;
    
    try {
      // Use bounds around last known position or selected airport
      final Airport? airport = _selectedAirport;
      if (airport == null) return;
      
      final centerLat = _lastKnownPosition?.latitude ?? airport.location.latitude;
      final centerLon = _lastKnownPosition?.longitude ?? airport.location.longitude;
      
      final bounds = LatLngBounds(
        LatLng(centerLat - 2, centerLon - 2),
        LatLng(centerLat + 2, centerLon + 2),
      );
      
      final url = Uri.parse(
        'https://opensky-network.org/api/states/all?lamin=${bounds.south}&lomin=${bounds.west}&lamax=${bounds.north}&lomax=${bounds.east}',
      );
      
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> states = data['states'] ?? [];
        
        // Find the tracked aircraft
        for (var state in states) {
          final icao24 = state[0];
          if (icao24 == _trackedIcao24) {
            final lat = state[6];
            final lon = state[5];
            final heading = (state[10] ?? 0.0) as double;
            final velocity = (state[9] ?? 0.0) as double;
            
            if (lat != null && lon != null && mounted) {
              setState(() {
                _lastKnownPosition = LatLng(lat, lon);
                _lastKnownHeading = heading;
                _lastKnownVelocity = velocity;
              });
              
              // Update marker position
              _updateTrackedAircraftMarker();
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Błąd odświeżania pozycji śledzonego samolotu: $e');
    }
  }
  
  void _updateAircraftPositionInterpolation() {
    if (_trackedIcao24 == null || 
        _lastKnownPosition == null || 
        _lastKnownHeading == null ||
        _lastKnownVelocity == null) return;
    
    // Simple interpolation: move in the direction of heading
    // Convert velocity from m/s to degrees per second (rough approximation)
    // 1 m/s ≈ 0.000009 degrees at equator
    final velocity = _lastKnownVelocity!;
    final heading = _lastKnownHeading!;
    final position = _lastKnownPosition!;
    
    final speedDegreesPerSecond = (velocity / 111320.0) * 3.0; // 3 seconds
    
    final headingRad = heading * math.pi / 180.0;
    final deltaLat = speedDegreesPerSecond * math.cos(headingRad);
    final deltaLon = speedDegreesPerSecond * math.sin(headingRad) / math.cos(position.latitude * math.pi / 180.0);
    
    final newPosition = LatLng(
      position.latitude + deltaLat,
      position.longitude + deltaLon,
    );
    
    if (mounted) {
      setState(() {
        _lastKnownPosition = newPosition;
        // Dodaj nową pozycję do postępującej trasy
        _trackedFlightPath.add(newPosition);
      });
      _updateTrackedAircraftMarker();
    }
  }
  
  void _updateTrackedAircraftMarker() {
    if (_trackedIcao24 == null || _lastKnownPosition == null) return;
    
    // Użyj zapamiętanego indeksu markera lub znajdź go po pozycji
    int? trackedIndex = _trackedMarkerIndex;
    
    // Sprawdź czy indeks jest nadal poprawny
    if (trackedIndex == null || 
        trackedIndex < 0 || 
        trackedIndex >= _aircraftMarkers.length) {
      // Znajdź marker po pozycji (fallback)
      trackedIndex = _aircraftMarkers.indexWhere((marker) {
        final markerPos = marker.point;
        final trackedPos = _lastKnownPosition!;
        final distance = _distanceCalculator(markerPos, trackedPos);
        return distance < 0.1; // Tolerancja ~10km dla fallback
      });
      if (trackedIndex != -1) {
        _trackedMarkerIndex = trackedIndex; // Zapamiętaj dla następnych aktualizacji
      }
    }
    
    // Zawsze aktualizuj trasy (stara pomarańczowa + nowa zielona)
    setState(() {
      _flightPaths.clear();
      if (_historicalFlightPath.isNotEmpty) {
        _flightPaths.add(Polyline(
          points: _historicalFlightPath,
          color: Colors.orange,
          strokeWidth: 2.5,
        ));
      }
      if (_trackedFlightPath.length > 1) {
        _flightPaths.add(Polyline(
          points: _trackedFlightPath,
          color: Colors.green,
          strokeWidth: 2.5,
        ));
      }
      
      // Aktualizuj marker jeśli znaleziono - pozycję i heading
      if (trackedIndex != null && trackedIndex != -1 && trackedIndex < _aircraftMarkers.length) {
        // Utwórz nowy marker z zaktualizowaną pozycją i headingiem
        final newMarker = _markerWithCallsign(
          position: _lastKnownPosition!,
          heading: _lastKnownHeading ?? 0.0,
          callsign: _trackedCallsign ?? 'Tracked',
          isTracked: true,
          onTap: () async {
            // Zachowaj funkcjonalność kliknięcia - pobierz trasę i pokaż dialog
            final track = await fetchFlightTrack(_trackedIcao24!);
            setState(() {
              _flightPaths.clear();
              if (_historicalFlightPath.isNotEmpty) {
                _flightPaths.add(Polyline(
                  points: _historicalFlightPath,
                  color: Colors.orange,
                  strokeWidth: 2.5,
                ));
              }
              if (track.isNotEmpty) {
                _flightPaths.add(Polyline(
                  points: track,
                  color: Colors.orange,
                  strokeWidth: 2.5,
                ));
              }
              if (_trackedFlightPath.length > 1) {
                _flightPaths.add(Polyline(
                  points: _trackedFlightPath,
                  color: Colors.green,
                  strokeWidth: 2.5,
                ));
              }
            });
            
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Samolot: ${_trackedCallsign ?? "Tracked"}'),
                content: Text(
                  'Pozycja: (${_lastKnownPosition!.latitude.toStringAsFixed(4)}, ${_lastKnownPosition!.longitude.toStringAsFixed(4)})\n'
                  'Kierunek: ${(_lastKnownHeading ?? 0.0).toStringAsFixed(1)}°\n'
                  '✓ Śledzony na żywo',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _stopLiveTracking();
                      fetchAircraftPositions();
                    },
                    child: const Text('Zatrzymaj śledzenie'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zamknij'),
                  ),
                ],
              ),
            );
          },
        );
        
        _aircraftMarkers[trackedIndex] = newMarker;
      }
    });
  }

  Future<List<LatLng>> fetchFlightTrack(String icao24) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final url = Uri.parse(
      'https://opensky-network.org/api/tracks/all?icao24=$icao24&time=$timestamp',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> track = data['path'] ?? [];
      return track.map<LatLng>((coord) => LatLng(coord[1], coord[2])).toList();
    } else {
      print('Nie udało się pobrać śladu lotu dla $icao24');
      return [];
    }
  }

  Future<void> fetchAircraftPositions() async {
    if (_selectedIcao.isEmpty) {
      print('Nie wybrano lotniska — nie pobieram danych.');
      return;
    }

    // Ustaw bounding box wokół wybranego lotniska, np. ±2 stopnie
    final Airport? airport = _selectedAirport;
    if (airport == null) return;

    final bounds = LatLngBounds(
      LatLng(airport.location.latitude - 2, airport.location.longitude - 2),
      LatLng(airport.location.latitude + 2, airport.location.longitude + 2),
    );

    final url = Uri.parse(
      'https://opensky-network.org/api/states/all?lamin=${bounds.south}&lomin=${bounds.west}&lamax=${bounds.north}&lomax=${bounds.east}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      print('Nie udało się pobrać danych o samolotach.');
      return;
    }

    final data = json.decode(response.body);
    final List<dynamic> states = data['states'] ?? [];

    final LatLng airportLocation = airport.location;

    final newMarkers = <Marker>[];
    final newFlightPaths = <Polyline>[];

    for (var state in states) {
      final lat = state[6];
      final lon = state[5];
      final icao24 = state[0];
      final callsign = (state[1] ?? 'Brak').toString().trim();
      final heading = (state[10] ?? 0.0) as double;
      final originCountry = state[2] ?? 'Nieznany';

      // Use tracked position if this is the tracked aircraft
      LatLng position;
      if (_trackedIcao24 == icao24 && _lastKnownPosition != null) {
        position = _lastKnownPosition!;
      } else {
        if (lat == null || lon == null) continue;
        position = LatLng(lat, lon);
      }
      
      final distanceToAirport = _distanceCalculator(position, airportLocation);

      if (distanceToAirport > 50000) continue;

      final isTracked = _trackedIcao24 == icao24;
      final markerIndex = newMarkers.length; // Indeks tego markera w nowej liście

      newMarkers.add(
        _markerWithCallsign(
          position: position,
          heading: isTracked && _lastKnownHeading != null ? _lastKnownHeading! : heading,
          callsign: callsign,
          isTracked: isTracked,
          onTap: () async {
            // Start live tracking for this aircraft
            if (_trackedIcao24 != icao24) {
              _startLiveTracking(
                icao24: icao24,
                initialLat: position.latitude,
                initialLon: position.longitude,
                initialHeading: heading,
                callsign: callsign,
                markerIndex: markerIndex,
              );
            }
            
            final track = await fetchFlightTrack(icao24);
            setState(() {
              _flightPaths.clear();
              if (track.isNotEmpty) {
                _flightPaths.add(Polyline(
                  points: track,
                  color: Colors.orange,
                  strokeWidth: 2.5,
                ));
              }
            });

            // Log flight tracking to Firebase
            try {
              await _firebaseService.saveFlightTracking(
                icao24: icao24,
                callsign: callsign,
                airport: _selectedIcao,
                latitude: position.latitude,
                longitude: position.longitude,
                heading: heading,
              );
            } catch (e) {
              print('Błąd zapisywania śledzenia lotu: $e');
            }

            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Samolot: $callsign'),
                content: Text(
                  'Kraj pochodzenia: $originCountry\n'
                  'Pozycja: (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})\n'
                  'Kierunek: ${heading.toStringAsFixed(1)}°\n'
                  '${isTracked ? "✓ Śledzony na żywo" : ""}',
                ),
                actions: [
                  if (isTracked)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _stopLiveTracking();
                        fetchAircraftPositions();
                      },
                      child: const Text('Zatrzymaj śledzenie'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Zamknij'),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    setState(() {
      _aircraftMarkers
        ..clear()
        ..addAll(newMarkers);
      _flightPaths
        ..clear()
        ..addAll(newFlightPaths);
      
      // Zaktualizuj indeks markera śledzonego samolotu jeśli jest śledzony
      if (_trackedIcao24 != null) {
        _trackedMarkerIndex = newMarkers.indexWhere((marker) {
          // Znajdź marker po icao24 - sprawdź czy to jest śledzony samolot
          // Używamy pozycji jako identyfikatora (najbliższy do ostatniej znanej pozycji)
          if (_lastKnownPosition != null) {
            final distance = _distanceCalculator(marker.point, _lastKnownPosition!);
            return distance < 0.05; // Tolerancja ~5km
          }
          return false;
        });
        
        // Jeśli nie znaleziono, spróbuj znaleźć po callsign w onTap callback
        if (_trackedMarkerIndex == -1 && _trackedCallsign != null) {
          // Nie możemy łatwo sprawdzić callsign z markera, więc użyjemy pozycji
          // To zostanie zaktualizowane przy następnej aktualizacji
        }
      }
    });
  }

  Marker _markerWithCallsign({
    required LatLng position,
    required double heading,
    required String callsign,
    required VoidCallback onTap,
    bool isTracked = false,
  }) {
    return Marker(
      width: 100.0,
      height: 80.0,
      point: position,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
              child: Text(
                callsign,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: Icon(
                Icons.flight, 
                color: isTracked ? Colors.green : Colors.red, 
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playLiveStreamForAirport(String icao) async {
    print('_playLiveStreamForAirport called with icao: $icao');
    print('Current state: listeningIcao=$_listeningIcao, isPlaying=$_isPlaying');
    
    // Jeśli już odtwarzamy ten stream, zatrzymaj go
    if (_listeningIcao == icao && _isPlaying) {
      print('Stopping current stream (same airport)');
      await _audioPlayer.stop();
      return;
    }

    // Jeśli odtwarzamy inny stream, zatrzymaj go najpierw
    if (_isPlaying && _listeningIcao != icao) {
      print('Stopping current stream (different airport)');
      await _audioPlayer.stop();
    }

    // Pobierz wszystkie streamy dla lotniska
    List<Map<String, dynamic>> streams = [];
    try {
      streams = await _firebaseService.getUserStreamsForAirport(icao);
    } catch (e) {
      print('Błąd pobierania streamów użytkownika: $e');
    }

    if (streams.isEmpty) {
      print('Brak streamu dla lotniska $icao');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Brak streamu dla lotniska $icao'),
            action: SnackBarAction(
              label: 'Dodaj stream',
              onPressed: () => _showAddStreamDialog(icao),
            ),
          ),
        );
      }
      return;
    }

    // Jeśli jest tylko jeden stream, odtwórz go od razu
    if (streams.length == 1) {
      final stream = streams.first;
      final streamUrl = stream['streamUrl'] as String?;
      final streamName = stream['streamName'] as String?;
      if (streamUrl != null) {
        await _playStream(streamUrl, streamName ?? 'Stream $icao', icao);
      }
      return;
    }

    // Jeśli jest więcej streamów, pokaż dialog wyboru
    final selectedStream = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wybierz stream dla $icao'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              final streamName = stream['streamName'] as String?;
              final streamUrl = stream['streamUrl'] as String;
              
              return ListTile(
                leading: const Icon(Icons.radio),
                title: Text(streamName ?? 'Stream ${index + 1}'),
                subtitle: Text(
                  streamUrl,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.of(context).pop(stream),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );

    if (selectedStream != null) {
      final streamUrl = selectedStream['streamUrl'] as String?;
      final streamName = selectedStream['streamName'] as String?;
      if (streamUrl != null) {
        await _playStream(streamUrl, streamName ?? 'Stream $icao', icao);
      }
    }
  }

  Future<void> _playStream(String streamUrl, String streamName, String icao) async {
    print('Playing stream: $streamUrl, name: $streamName');
    try {
      // Ustaw stan przed inicjalizacją, aby uniknąć błędnych powiadomień
      // Nie resetuj stanu jeśli już jest ustawiony (podczas zmiany streamu)
      setState(() {
        _listeningIcao = icao;
        // Zawsze ustaw nazwę streamu, nawet jeśli to domyślna nazwa
        _currentStreamName = streamName.isNotEmpty ? streamName : null;
        _currentStreamUrl = streamUrl;
        _isPlaying = true; // Ustaw od razu, listener zaktualizuje jeśli trzeba
      });
      print('Set _currentStreamName to: $_currentStreamName, listeningIcao: $_listeningIcao, isPlaying: $_isPlaying');

      // Zatrzymaj poprzedni stream przed załadowaniem nowego
      try {
        await _audioPlayer.stop();
      } catch (e) {
        // Ignoruj błędy przy zatrzymywaniu
      }

      // Ustaw nowy URL i odtwórz
      await _audioPlayer.setUrl(streamUrl);
      
      // Daj chwilę na inicjalizację przed odtworzeniem
      await Future.delayed(const Duration(milliseconds: 100));
      
      await _audioPlayer.play();
      print('AudioPlayer.play() called, setting state...');
      print('Stream started: icao=$icao, name=$_currentStreamName, listeningIcao=$_listeningIcao');
    } catch (e) {
      print('Błąd odtwarzania streamu: $e');
      // Resetuj stan tylko jeśli to prawdziwy błąd
      setState(() {
        if (_listeningIcao == icao) {
          _listeningIcao = null;
          _currentStreamName = null;
          _currentStreamUrl = null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd odtwarzania streamu: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _stopStream() async {
    print('Stopping stream: listeningIcao=$_listeningIcao');
    await _audioPlayer.stop();
      setState(() {
        _listeningIcao = null;
        _currentStreamName = null;
        _currentStreamUrl = null;
      });
    print('Stream stopped: listeningIcao=$_listeningIcao');
  }

  Future<void> _changeStream() async {
    if (_listeningIcao == null || _listeningIcao!.isEmpty) return;

    // Pobierz wszystkie streamy dla lotniska
    List<Map<String, dynamic>> streams = [];
    try {
      streams = await _firebaseService.getUserStreamsForAirport(_listeningIcao!);
    } catch (e) {
      print('Błąd pobierania streamów: $e');
      return;
    }

    if (streams.length <= 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brak innych streamów dla tego lotniska'),
          ),
        );
      }
      return;
    }

    // Pokaż dialog wyboru streamu
    final selectedStream = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Zmień stream dla $_listeningIcao'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: streams.length,
            itemBuilder: (context, index) {
              final stream = streams[index];
              final streamName = stream['streamName'] as String?;
              final streamUrl = stream['streamUrl'] as String;
              final isCurrent = streamUrl == _currentStreamUrl;
              
              return ListTile(
                leading: Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isCurrent ? Colors.green : Colors.grey,
                ),
                title: Text(streamName ?? 'Stream ${index + 1}'),
                subtitle: Text(
                  streamUrl,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isCurrent 
                    ? const Text('Aktualny', style: TextStyle(color: Colors.green, fontSize: 12))
                    : null,
                onTap: () => Navigator.of(context).pop(stream),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );

    if (selectedStream != null) {
      final streamUrl = selectedStream['streamUrl'] as String?;
      final streamName = selectedStream['streamName'] as String?;
      if (streamUrl != null) {
        // Zapisz aktualne ICAO przed zmianą
        final currentIcao = _listeningIcao;
        // Ustaw stan przed zatrzymaniem, aby uniknąć resetowania
        setState(() {
          _listeningIcao = currentIcao;
          _currentStreamName = streamName?.isNotEmpty == true ? streamName : null;
          _currentStreamUrl = streamUrl;
          _isPlaying = true;
        });
        print('Changing stream - set _currentStreamName to: $_currentStreamName, listeningIcao: $_listeningIcao');
        await _playStream(streamUrl, streamName ?? 'Stream $_listeningIcao', _listeningIcao!);
      }
    }
  }

  Future<void> _showAddStreamDialog(String airportIcao) async {
    final streamNameController = TextEditingController();
    final streamUrlController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dodaj stream dla $airportIcao'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: streamNameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa streamu (opcjonalnie)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: streamUrlController,
              decoration: const InputDecoration(
                labelText: 'URL streamu *',
                border: OutlineInputBorder(),
                hintText: 'http://example.com/stream.mp3',
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              if (streamUrlController.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL streamu jest wymagany')),
                );
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _firebaseService.saveUserStream(
          airportIcao: airportIcao,
          streamUrl: streamUrlController.text.trim(),
          streamName: streamNameController.text.trim().isEmpty 
              ? null 
              : streamNameController.text.trim(),
        );

        await _loadUserStreams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stream został dodany')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd zapisywania streamu: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool noAirportSelected = _selectedIcao.isEmpty;
    final bool isListening = _listeningIcao != null; // Uproszczony warunek
    final bool hasStreamForSelected = _selectedIcao.isNotEmpty &&
        _userStreams.any((s) => s['airportIcao'] == _selectedIcao);
    
    print('Build: listeningIcao=$_listeningIcao, isListening=$isListening, isPlaying=$_isPlaying');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mapa lotów'),
            if (isListening && _currentStreamName != null)
              Text(
                '🎧 $_currentStreamName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        actions: [
          // Stop stream button
          if (_listeningIcao != null)
            IconButton(
              icon: const Icon(Icons.stop),
              tooltip: 'Zatrzymaj stream',
              onPressed: _stopStream,
            ),
          PopupMenuButton<String>(
            tooltip: 'Wybierz lotnisko',
            icon: const Icon(Icons.local_airport),
            onSelected: (icao) async {
              setState(() {
                _selectedIcao = icao;
              });
              await fetchAircraftPositions();
              await _playLiveStreamForAirport(icao);
            },
            itemBuilder: (context) {
              return airports.map((airport) {
                final hasStream = _userStreams.any((s) => s['airportIcao'] == airport.icao);
                return PopupMenuItem(
                  value: airport.icao,
                  child: Row(
                    children: [
                      Icon(
                        hasStream ? Icons.radio : Icons.radio_outlined,
                        size: 16,
                        color: hasStream ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(airport.icao),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          IconButton(
            tooltip: 'Loty',
            icon: const Icon(Icons.flight_takeoff),
            onPressed: noAirportSelected
                ? null
                : () async {
                    final result = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (context) =>
                            FlightsBoardScreen(initialAirport: _selectedIcao),
                      ),
                    );
                    
                    if (result != null && mounted) {
                      // Center map on selected flight
                      final lat = result['latitude'] as double;
                      final lon = result['longitude'] as double;
                      final icao24 = result['icao24'] as String;
                      final heading = result['heading'] as double? ?? 0.0;
                      
                      _mapController.move(LatLng(lat, lon), 12.0);
                      
                      // Start live tracking for this aircraft
                      final callsign = result['callsign'] as String?;
                      
                      // Ustaw podstawowe dane śledzenia przed pobraniem markerów
                      _trackedIcao24 = icao24;
                      _trackedCallsign = callsign;
                      _lastKnownPosition = LatLng(lat, lon);
                      _lastKnownHeading = heading;
                      
                      // Refresh aircraft positions first to get markers and find the tracked one
                      await fetchAircraftPositions();
                      
                      // Then start full tracking with timers (markerIndex should be set now)
                      _startLiveTracking(
                        icao24: icao24,
                        initialLat: lat,
                        initialLon: lon,
                        initialHeading: heading,
                        callsign: callsign,
                        markerIndex: _trackedMarkerIndex, // Powinien być ustawiony przez fetchAircraftPositions
                      );
                    }
                  },
          ),
          IconButton(
            tooltip: 'Informacje lotniskowe',
            icon: const Icon(Icons.info_outline),
            onPressed: noAirportSelected
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AirportInfoScreen(airportIcao: _selectedIcao),
                      ),
                    );
                  },
          ),
          IconButton(
            tooltip: 'Zdjęcia samolotów',
            icon: const Icon(Icons.photo_camera),
            onPressed: noAirportSelected
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AircraftPhotosScreen(airportIcao: _selectedIcao),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież pozycje samolotów',
            onPressed: noAirportSelected ? null : fetchAircraftPositions,
          ),
          IconButton(
            icon: const Icon(Icons.radio),
            tooltip: 'Moje streamy',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const StreamsManagementScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ustawienia',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            tooltip: 'Informacje',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Informacje'),
                  content:
                      const Text('Aplikacja TowerFlower - centrum informacji lotniskowej.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Zamknij'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(52.2297, 21.0122),
          initialZoom: 6.5,
        ),
        children: [
          TileLayer(
            urlTemplate: _mapLayers[_currentLayerIndex].urlTemplate,
            subdomains: _mapLayers[_currentLayerIndex].subdomains,
            userAgentPackageName: 'com.example.towerflower',
            tileProvider: CancellableNetworkTileProvider(),
          ),
          MarkerLayer(
            markers: airports.map((airport) {
              final isActive = airport.icao == _listeningIcao;
              final hasStream = _userStreams.any((s) => s['airportIcao'] == airport.icao);
              return Marker(
                point: airport.location,
                width: 50,
                height: 50,
                child: GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedIcao = airport.icao;
                    });
                    await fetchAircraftPositions();
                    await _playLiveStreamForAirport(airport.icao);
                  },
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isActive ? Colors.green : Colors.blue,
                            size: 30,
                          ),
                          if (hasStream)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                                child: const Icon(
                                  Icons.radio,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        airport.icao,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          PolylineLayer(polylines: _flightPaths),
          MarkerLayer(markers: _aircraftMarkers),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.extended(
              heroTag: 'layer_toggle',
              icon: const Icon(Icons.layers),
              label: Text(_mapLayers[_currentLayerIndex].name),
              onPressed: () {
                setState(() {
                  _currentLayerIndex =
                      (_currentLayerIndex + 1) % _mapLayers.length;
                });
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          color: Colors.grey[200],
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: 8 + MediaQuery.of(context).padding.bottom / 2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Wybrane lotnisko: ${_selectedIcao.isEmpty ? "Brak" : _selectedIcao}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isPlaying
                          ? _stopStream
                          : (hasStreamForSelected
                              ? () => _playLiveStreamForAirport(_selectedIcao)
                              : null),
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Zatrzymaj' : 'Odtwórz'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.radio,
                      color: _isPlaying ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (_isPlaying || _listeningIcao != null)
                            ? 'Nasłuchujesz: ${_listeningIcao ?? _selectedIcao}${_currentStreamName != null && _currentStreamName!.isNotEmpty ? ' - $_currentStreamName' : ''}'
                            : 'Brak aktywnego nasłuchu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (_isPlaying || _listeningIcao != null) ? Colors.green : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if ((_isPlaying || _listeningIcao != null) && _listeningIcao != null && _listeningIcao!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Zmień stream',
                          onPressed: _changeStream,
                          iconSize: 24,
                          color: Colors.blue,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
