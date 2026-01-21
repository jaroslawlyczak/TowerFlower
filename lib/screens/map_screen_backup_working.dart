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
import '../models/airport.dart';
import '../models/aircraft.dart';
import '../models/airport_flight.dart'; // Import AircraftCategory
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

/// Klasa pomocnicza do przechowywania snapshotów pozycji samolotu
class _AircraftSnapshot {
  final LatLng position;
  final double heading;
  final double velocity;
  final DateTime timestamp;
  
  _AircraftSnapshot({
    required this.position,
    required this.heading,
    required this.velocity,
    required this.timestamp,
  });
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final List<Marker> _aircraftMarkers = [];
  final List<Polyline> _flightPaths = [];
  Marker? _trackedAircraftMarker; // Osobny marker dla śledzonego samolotu
  String _selectedIcao = '';
  String? _listeningIcao;
  String? _currentStreamName;
  String? _currentStreamUrl;
  bool _isPlaying = false;
  List<Map<String, dynamic>> _userStreams = [];
  DateTime? _lastFetchTime; // Ostatni czas pobrania pozycji wszystkich samolotów
  bool _isFetching = false; // Flaga zapobiegająca równoczesnym zapytaniom
  
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
  
  // Tracker z ostatnimi pozycjami z API (do przewidywania trasy)
  final List<_AircraftSnapshot> _recentPositions = []; // Ostatnie 3-5 pozycji z API

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
    WidgetsBinding.instance.addObserver(this);
    _setupAudioPlayer();
    _loadUserStreams();
    _loadAirports();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopLiveTracking();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Gdy aplikacja wraca do foreground, przeładuj lotniska
    if (state == AppLifecycleState.resumed) {
      _loadAirports();
    }
  }

  Future<void> _loadAirports() async {
    try {
      await loadAirports();
      if (mounted) {
        setState(() {
          // Odśwież ekran, aby pokazać nowe lotniska
        });
      }
    } catch (e) {
      print('Błąd ładowania lotnisk: $e');
    }
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
    _lastApiPosition = null;
    _interpolationStartPosition = null;
    _lastApiUpdateTime = null;
    _recentPositions.clear();
    _trackedFlightPath.clear();
    _historicalFlightPath.clear();
    setState(() {
      _flightPaths.clear();
      _trackedAircraftMarker = null;
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
    // Zatrzymaj poprzednie śledzenie jeśli było aktywne
    _liveTrackingTimer?.cancel();
    _apiRefreshTimer?.cancel();
    _liveTrackingTimer = null;
    _apiRefreshTimer = null;
    
    // Wyczyść trasę poprzedniego samolotu
    _trackedFlightPath.clear();
    _historicalFlightPath.clear();
    _recentPositions.clear();
    
    // Wyczyść wyświetlane trasy
    setState(() {
      _flightPaths.clear();
    });
    
    // Ustaw dane śledzenia PRZED odświeżeniem listy samolotów
    _trackedIcao24 = icao24;
    _trackedCallsign = callsign ?? _trackedCallsign;
    _trackedMarkerIndex = markerIndex ?? _trackedMarkerIndex;
    _lastKnownPosition = LatLng(initialLat, initialLon);
    _lastKnownHeading = initialHeading;
    _lastKnownVelocity = 0.0; // Będzie zaktualizowane z API
    _trackedFlightPath = [LatLng(initialLat, initialLon)]; // Rozpocznij nową trasę
    _interpolationStartPosition = LatLng(initialLat, initialLon);
    _lastApiPosition = LatLng(initialLat, initialLon);
    _lastApiUpdateTime = DateTime.now();
    
    // Utwórz marker śledzonego samolotu od razu - będzie aktualizowany przez _updateTrackedAircraftMarker()
    _updateTrackedAircraftMarker();
    
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
    
    // API refresh every 3 seconds
    _apiRefreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _refreshTrackedAircraftPosition();
    });
    
    // Interpolation update every 100ms for very smooth movement
    _liveTrackingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateAircraftPositionInterpolation();
    });
    
    // Initial API refresh
    _refreshTrackedAircraftPosition();
  }
  
  Future<void> _refreshTrackedAircraftPosition() async {
    if (_trackedIcao24 == null || _selectedIcao.isEmpty) return;
    
    try {
      // Użyj bardzo małego obszaru wokół ostatniej znanej pozycji śledzonego samolotu
      // ±0.1 stopnia = ~11km - wystarczy dla jednego samolotu, znacznie mniej danych
      if (_lastKnownPosition == null) {
        // Jeśli nie mamy pozycji, użyj lotniska ale z małym obszarem
        final Airport? airport = _selectedAirport;
        if (airport == null) return;
        
        final bounds = LatLngBounds(
          LatLng(airport.location.latitude - 0.1, airport.location.longitude - 0.1),
          LatLng(airport.location.latitude + 0.1, airport.location.longitude + 0.1),
        );
        
        final url = Uri.parse(
          'https://opensky-network.org/api/states/all?lamin=${bounds.south}&lomin=${bounds.west}&lamax=${bounds.north}&lomax=${bounds.east}',
        );
        
        final response = await http.get(url);
        
        // Obsługa rate limiting (429 Too Many Requests)
        if (response.statusCode == 429) {
          print('Rate limit przekroczony - czekam dłużej przed następnym zapytaniem');
          // Zwiększ interwał do 10 sekund jeśli rate limit (tymczasowo)
          _apiRefreshTimer?.cancel();
          _apiRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
            _refreshTrackedAircraftPosition();
          });
          return;
        }
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> states = data['states'] ?? [];
          
          // Znajdź śledzony samolot
          for (var state in states) {
            final icao24 = state[0];
            if (icao24 == _trackedIcao24) {
              final lat = state[6];
              final lon = state[5];
              final heading = (state[10] ?? 0.0) as double;
              final velocity = (state[9] ?? 0.0) as double;
              
              if (lat != null && lon != null && mounted) {
                final newPosition = LatLng(lat, lon);
                final now = DateTime.now();
                
                // Dodaj nową pozycję do trackera (ostatnie 5 pozycji)
                _recentPositions.add(_AircraftSnapshot(
                  position: newPosition,
                  heading: heading,
                  velocity: velocity,
                  timestamp: now,
                ));
                
                // Zachowaj tylko ostatnie 5 pozycji
                if (_recentPositions.length > 5) {
                  _recentPositions.removeAt(0);
                }
                
                // Zapamiętaj aktualną pozycję interpolowaną jako start dla nowej interpolacji
                // Użyj aktualnej pozycji interpolowanej, jeśli istnieje, w przeciwnym razie użyj ostatniej pozycji z API
                final currentInterpolatedPosition = _lastKnownPosition ?? _lastApiPosition ?? newPosition;
                
                // Jeśli to pierwsza aktualizacja z API, ustaw pozycję i rozpocznij trasę
                if (_trackedFlightPath.isEmpty) {
                  _trackedFlightPath = [newPosition];
                  setState(() {
                    _lastKnownPosition = newPosition;
                    _interpolationStartPosition = newPosition;
                    _lastApiPosition = newPosition;
                    _lastApiUpdateTime = now;
                    _lastKnownHeading = heading;
                    _lastKnownVelocity = velocity;
                  });
                } else {
                  // Sprawdź odległość od ostatniej pozycji w trasie
                  final lastPathPosition = _trackedFlightPath.last;
                  final distanceFromLast = _distanceCalculator(lastPathPosition, newPosition);
                  
                  // Dodaj nową pozycję do trasy tylko jeśli jest wystarczająco daleko (min 10m)
                  if (distanceFromLast > 0.01) {
                    _trackedFlightPath.add(newPosition);
                    
                    // Jeśli trasa ma więcej niż 100 punktów, usuń najstarsze
                    if (_trackedFlightPath.length > 100) {
                      _trackedFlightPath.removeAt(0);
                    }
                  }
                  
                  // Ustaw pozycję startową interpolacji jako aktualną pozycję interpolowaną
                  // Cel to nowa pozycja z API - interpolacja będzie płynnie przechodzić od startu do celu
                  setState(() {
                    // Użyj aktualnej pozycji interpolowanej jako startu (nie pozycji z API)
                    _interpolationStartPosition = currentInterpolatedPosition;
                    _lastApiPosition = newPosition; // Cel dla interpolacji
                    _lastApiUpdateTime = now;
                    _lastKnownHeading = heading;
                    _lastKnownVelocity = velocity;
                  });
                }
                
                // Update marker position
                _updateTrackedAircraftMarker();
              }
              break;
            }
          }
        }
        return;
      }
      
      // Użyj bardzo małego obszaru wokół ostatniej pozycji śledzonego samolotu
      final centerLat = _lastKnownPosition!.latitude;
      final centerLon = _lastKnownPosition!.longitude;
      
      // ±0.1 stopnia = ~11km - wystarczy dla jednego samolotu, znacznie mniej danych niż ±2 stopnie
      final bounds = LatLngBounds(
        LatLng(centerLat - 0.1, centerLon - 0.1),
        LatLng(centerLat + 0.1, centerLon + 0.1),
      );
      
      final url = Uri.parse(
        'https://opensky-network.org/api/states/all?lamin=${bounds.south}&lomin=${bounds.west}&lamax=${bounds.north}&lomax=${bounds.east}',
      );
      
      final response = await http.get(url);
      
      // Obsługa rate limiting (429 Too Many Requests)
      if (response.statusCode == 429) {
        print('Rate limit przekroczony - czekam dłużej przed następnym zapytaniem');
        // Zwiększ interwał do 10 sekund jeśli rate limit (tymczasowo)
        _apiRefreshTimer?.cancel();
        _apiRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          _refreshTrackedAircraftPosition();
        });
        return;
      }
      
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
              final newPosition = LatLng(lat, lon);
              final now = DateTime.now();
              
              // Dodaj nową pozycję do trackera (ostatnie 5 pozycji)
              _recentPositions.add(_AircraftSnapshot(
                position: newPosition,
                heading: heading,
                velocity: velocity,
                timestamp: now,
              ));
              
              // Zachowaj tylko ostatnie 5 pozycji
              if (_recentPositions.length > 5) {
                _recentPositions.removeAt(0);
              }
              
              // Zapamiętaj aktualną pozycję interpolowaną jako start dla nowej interpolacji
              // Użyj aktualnej pozycji interpolowanej, jeśli istnieje, w przeciwnym razie użyj ostatniej pozycji z API
              final currentInterpolatedPosition = _lastKnownPosition ?? _lastApiPosition ?? newPosition;
              
              // Jeśli to pierwsza aktualizacja z API, ustaw pozycję i rozpocznij trasę
              if (_trackedFlightPath.isEmpty) {
                _trackedFlightPath = [newPosition];
                setState(() {
                  _lastKnownPosition = newPosition;
                  _interpolationStartPosition = newPosition;
                  _lastApiPosition = newPosition;
                  _lastApiUpdateTime = now;
                  _lastKnownHeading = heading;
                  _lastKnownVelocity = velocity;
                });
              } else {
                // Sprawdź odległość od ostatniej pozycji w trasie
                final lastPathPosition = _trackedFlightPath.last;
                final distanceFromLast = _distanceCalculator(lastPathPosition, newPosition);
                
                // Dodaj nową pozycję do trasy tylko jeśli jest wystarczająco daleko (min 10m)
                if (distanceFromLast > 0.01) {
                  _trackedFlightPath.add(newPosition);
                  
                  // Jeśli trasa ma więcej niż 100 punktów, usuń najstarsze
                  if (_trackedFlightPath.length > 100) {
                    _trackedFlightPath.removeAt(0);
                  }
                }
                
                // Ustaw pozycję startową interpolacji jako aktualną pozycję interpolowaną
                // Cel to nowa pozycja z API - interpolacja będzie płynnie przechodzić od startu do celu
                setState(() {
                  _interpolationStartPosition = currentInterpolatedPosition;
                  _lastApiPosition = newPosition; // Cel dla interpolacji
                  _lastApiUpdateTime = now;
                  _lastKnownHeading = heading;
                  _lastKnownVelocity = velocity;
                });
              }
              
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
  
  LatLng? _lastApiPosition; // Ostatnia pozycja z API (bez interpolacji)
  LatLng? _interpolationStartPosition; // Pozycja startowa dla interpolacji
  DateTime? _lastApiUpdateTime; // Czas ostatniej aktualizacji z API
  
  void _updateAircraftPositionInterpolation() {
    if (_trackedIcao24 == null || 
        _lastApiPosition == null ||
        _interpolationStartPosition == null ||
        _lastKnownHeading == null ||
        _lastKnownVelocity == null ||
        _lastApiUpdateTime == null) {
      return;
    }
    
    final now = DateTime.now();
    final timeSinceApiUpdate = now.difference(_lastApiUpdateTime!).inMilliseconds / 1000.0;
    
    // Jeśli minęło więcej niż 3.5 sekundy od ostatniej aktualizacji API, użyj pozycji z API
    if (timeSinceApiUpdate > 3.5) {
      if (mounted) {
        setState(() {
          _lastKnownPosition = _lastApiPosition;
          _interpolationStartPosition = _lastApiPosition;
        });
        _updateTrackedAircraftMarker();
      }
      return;
    }
    
    final startPos = _interpolationStartPosition!;
    final targetPos = _lastApiPosition!;
    
    // Oblicz odległość do celu
    final distanceToTarget = _distanceCalculator(startPos, targetPos);
    
    // Jeśli jesteśmy bardzo blisko celu (mniej niż 10m), użyj pozycji z API
    if (distanceToTarget < 0.01) {
      if (mounted) {
        setState(() {
          _lastKnownPosition = targetPos;
          _interpolationStartPosition = targetPos;
        });
        _updateTrackedAircraftMarker();
      }
      return;
    }
    
    // Interpolacja liniowa między pozycją startową a celem
    // Użyj czasu od ostatniej aktualizacji API do obliczenia postępu (0.0 - 1.0)
    // Interpolujemy przez 3 sekundy (czas między aktualizacjami API)
    final progress = (timeSinceApiUpdate / 3.0).clamp(0.0, 1.0);
    
    // Użyj linear interpolation dla stałej prędkości (bez easing, żeby było bardziej realistyczne)
    // Lub użyj ease-in-out dla płynniejszego startu i końca
    final easedProgress = progress < 0.5
        ? 2 * progress * progress // ease-in
        : 1 - math.pow(-2 * progress + 2, 2) / 2; // ease-out
    
    // Interpoluj pozycję liniowo między startem a celem
    final interpolatedLat = startPos.latitude + (targetPos.latitude - startPos.latitude) * easedProgress;
    final interpolatedLon = startPos.longitude + (targetPos.longitude - startPos.longitude) * easedProgress;
    
    // Interpoluj również heading dla płynniejszego obrotu
    double startHeading = _recentPositions.length >= 2 
        ? _recentPositions[_recentPositions.length - 2].heading 
        : _lastKnownHeading!;
    double targetHeading = _recentPositions.isNotEmpty 
        ? _recentPositions.last.heading 
        : _lastKnownHeading!;
    
    // Normalizuj różnicę kątów (obsługa przejścia przez 0/360)
    double headingDiff = targetHeading - startHeading;
    if (headingDiff > 180) headingDiff -= 360;
    if (headingDiff < -180) headingDiff += 360;
    
    final interpolatedHeading = (startHeading + headingDiff * easedProgress) % 360;
    
    final newPosition = LatLng(interpolatedLat, interpolatedLon);
    
    if (mounted) {
      setState(() {
        _lastKnownPosition = newPosition;
        _lastKnownHeading = interpolatedHeading < 0 ? interpolatedHeading + 360 : interpolatedHeading;
      });
      _updateTrackedAircraftMarker();
    }
  }
  
  
  /// Wygładza trasę używając prostego wygładzania (średnia z sąsiednich punktów)
  List<LatLng> _smoothPath(List<LatLng> path) {
    if (path.length < 3) return path;
    
    final smoothed = <LatLng>[path.first]; // Zawsze zaczynamy od pierwszego punktu
    
    for (int i = 1; i < path.length - 1; i++) {
      final prev = path[i - 1];
      final curr = path[i];
      final next = path[i + 1];
      
      // Wyśrodkowana średnia dla wygładzenia
      final smoothedLat = (prev.latitude + curr.latitude * 2 + next.latitude) / 4;
      final smoothedLon = (prev.longitude + curr.longitude * 2 + next.longitude) / 4;
      
      smoothed.add(LatLng(smoothedLat, smoothedLon));
    }
    
    smoothed.add(path.last); // Zawsze kończymy na ostatnim punkcie
    return smoothed;
  }
  
  
  void _updateTrackedAircraftMarker() {
    if (_trackedIcao24 == null || _lastKnownPosition == null || !mounted) return;
    
    // Utwórz Aircraft dla śledzonego samolotu (bez typu - unknown)
    final trackedAircraft = Aircraft(
      icao24: _trackedIcao24!,
      callsign: _trackedCallsign ?? 'Tracked',
      originCountry: 'Unknown',
      longitude: _lastKnownPosition!.longitude,
      latitude: _lastKnownPosition!.latitude,
      altitude: 0.0,
      velocity: _lastKnownVelocity ?? 0.0,
      heading: _lastKnownHeading ?? 0.0,
      departureIcao: '',
      arrivalIcao: '',
      aircraftType: null,
    );
    
    // Utwórz nowy marker z zaktualizowaną pozycją i headingiem
    final newMarker = _markerWithAircraft(
      position: _lastKnownPosition!,
      heading: _lastKnownHeading ?? 0.0,
      callsign: _trackedCallsign ?? 'Tracked',
      aircraft: trackedAircraft,
      isTracked: true,
      onTap: () async {
        // Zachowaj funkcjonalność kliknięcia - pobierz trasę i pokaż dialog
        final track = await fetchFlightTrack(_trackedIcao24!);
        if (!mounted) return;
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
            // Wygładź trasę dla płynniejszego wyglądu
            final smoothedPath = _smoothPath(_trackedFlightPath);
            
            _flightPaths.add(Polyline(
              points: smoothedPath,
              color: Colors.green,
              strokeWidth: 2.5,
            ));
          }
        });
        
        if (!mounted) return;
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
    
    // Aktualizuj marker i trasy w setState
    setState(() {
      // Aktualizuj osobny marker dla śledzonego samolotu
      _trackedAircraftMarker = newMarker;
      
      // Zawsze aktualizuj trasy (stara pomarańczowa + nowa zielona)
      _flightPaths.clear();
      if (_historicalFlightPath.isNotEmpty) {
        _flightPaths.add(Polyline(
          points: _historicalFlightPath,
          color: Colors.orange,
          strokeWidth: 2.5,
        ));
      }
      if (_trackedFlightPath.length > 1) {
        // Wygładź trasę dla płynniejszego wyglądu
        final smoothedPath = _smoothPath(_trackedFlightPath);
        
        _flightPaths.add(Polyline(
          points: smoothedPath,
          color: Colors.green,
          strokeWidth: 2.5,
        ));
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
      return [];
    }
  }

  Future<void> fetchAircraftPositions() async {
    if (_selectedIcao.isEmpty) {
      return;
    }

    final Airport? airport = _selectedAirport;
    if (airport == null) return;

    // Używamy OpenSky Network API (darmowe, open source)
    await _fetchAircraftPositionsOpenSky();
  }

  /// Pobiera pozycje statków powietrznych z OpenSky Network API
  Future<void> _fetchAircraftPositionsOpenSky() async {
    if (_selectedIcao.isEmpty) return;
    
    // Zapobiegaj równoczesnym zapytaniom
    if (_isFetching) return;
    
    // Debouncing - nie odświeżaj częściej niż co 5 sekund
    final now = DateTime.now();
    if (_lastFetchTime != null && now.difference(_lastFetchTime!).inSeconds < 5) {
      return;
    }
    
    _isFetching = true;
    _lastFetchTime = now;
    
    final Airport? airport = _selectedAirport;
    if (airport == null) {
      _isFetching = false;
      return;
    }

    final bounds = LatLngBounds(
      LatLng(airport.location.latitude - 2, airport.location.longitude - 2),
      LatLng(airport.location.latitude + 2, airport.location.longitude + 2),
    );

    final url = Uri.parse(
      'https://opensky-network.org/api/states/all?lamin=${bounds.south}&lomin=${bounds.west}&lamax=${bounds.north}&lomax=${bounds.east}',
    );

    try {
      final response = await http.get(url);
      
      // Obsługa rate limiting (429 Too Many Requests)
      if (response.statusCode == 429) {
        print('Rate limit przekroczony przy pobieraniu pozycji samolotów');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zbyt wiele zapytań do API. Spróbuj ponownie za chwilę.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _isFetching = false;
        return;
      }
      
      if (response.statusCode != 200) {
        print('Nie udało się pobrać danych o samolotach. Status: ${response.statusCode}');
        _isFetching = false;
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
      final originCountry = state[2] ?? 'Unknown';

      // Jeśli to śledzony samolot, pomiń go - będzie wyświetlany jako osobny marker
      if (_trackedIcao24 == icao24) {
        continue; // Nie dodawaj śledzonego samolotu do listy - jest osobno
      }
      
      if (lat == null || lon == null) continue;
      final position = LatLng(lat, lon);
      
      final distanceToAirport = _distanceCalculator(position, airportLocation);
      if (distanceToAirport > 50000) continue;

      final markerIndex = newMarkers.length;

      // Utwórz Aircraft bez typu statku (OpenSky nie zwraca)
      final aircraft = Aircraft(
        icao24: icao24,
        callsign: callsign,
        originCountry: originCountry,
        longitude: lon ?? 0.0,
        latitude: lat ?? 0.0,
        altitude: (state[7] ?? 0.0).toDouble(),
        velocity: (state[9] ?? 0.0).toDouble(),
        heading: heading,
        departureIcao: '',
        arrivalIcao: '',
        aircraftType: null,
      );

      newMarkers.add(
        _markerWithAircraft(
          position: position,
          heading: heading,
          callsign: callsign,
          aircraft: aircraft,
          isTracked: false,
          onTap: () async {
            // Jeśli klikamy w inny samolot niż śledzony, zatrzymaj poprzednie śledzenie i wyczyść trasę
            if (_trackedIcao24 != null && _trackedIcao24 != icao24) {
              _stopLiveTracking();
            }
            
            // Rozpocznij śledzenie nowego samolotu (jeśli jeszcze nie śledzony)
            if (_trackedIcao24 != icao24) {
              // Ustaw _trackedIcao24 PRZED odświeżeniem listy, żeby samolot nie był dodawany do listy
              _trackedIcao24 = icao24;
              _startLiveTracking(
                icao24: icao24,
                initialLat: position.latitude,
                initialLon: position.longitude,
                initialHeading: heading,
                callsign: callsign,
                markerIndex: markerIndex,
              );
            }
            
            // Pobierz i wyświetl archiwalną trasę (tylko do podglądu)
            final track = await fetchFlightTrack(icao24);
            setState(() {
              // Nie czyść tras śledzonego samolotu - tylko dodaj archiwalną trasę jeśli nie jest śledzony
              if (_trackedIcao24 != icao24) {
                _flightPaths.clear();
                if (track.isNotEmpty) {
                  _flightPaths.add(Polyline(
                    points: track,
                    color: Colors.blue,
                    strokeWidth: 2.5,
                  ));
                  
                  // Wycentruj mapę tylko na samolocie (nie na środku trasy)
                  _mapController.move(position, 12.0);
                } else {
                  // Jeśli brak trasy, wycentruj tylko na samolocie
                  _mapController.move(position, 12.0);
                }
              }
            });
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
      });
    } catch (e) {
      print('Błąd pobierania pozycji samolotów: $e');
    } finally {
      _isFetching = false;
    }
  }

  /// Zwraca ikonę i rozmiar na podstawie kategorii statku powietrznego
  (IconData icon, double size) _getAircraftIconForMap(AircraftCategory category) {
    switch (category) {
      case AircraftCategory.small:
        return (Icons.airplanemode_active, 18.0);
      case AircraftCategory.medium:
        return (Icons.flight, 22.0);
      case AircraftCategory.large:
        return (Icons.local_airport, 26.0);
      case AircraftCategory.helicopter:
        return (Icons.toys, 20.0); // brak natywnej ikony helikoptera
      case AircraftCategory.unknown:
        return (Icons.flight, 20.0);
    }
  }

  Marker _markerWithAircraft({
    required LatLng position,
    required double heading,
    required String callsign,
    required Aircraft aircraft,
    required VoidCallback onTap,
    bool isTracked = false,
  }) {
    final (icon, size) = _getAircraftIconForMap(aircraft.category);
    
    // Struktura: banner na górze, ikona na dole
    // Chcemy, żeby punkt pozycji był na ikonie samolotu (na dole, na środku)
    // Używamy Stack z pozycjonowaniem, aby ikona była dokładnie na pozycji
    return Marker(
      width: 100.0,
      height: 80.0,
      point: position,
      alignment: Alignment.center, // Punkt pozycji w centrum markera
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Banner z callsign - przesunięty w górę
            Positioned(
              top: 0,
              child: Container(
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
            ),
            // Ikona samolotu - dokładnie w centrum (na pozycji)
            Transform.rotate(
              angle: heading * math.pi / 180,
              child: Icon(
                icon,
                color: isTracked ? Colors.green : Colors.red,
                size: size,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playLiveStreamForAirport(String icao) async {
    // Jeśli już odtwarzamy ten stream, zatrzymaj go
    if (_listeningIcao == icao && _isPlaying) {
      await _audioPlayer.stop();
      return;
    }

    // Jeśli odtwarzamy inny stream, zatrzymaj go najpierw
    if (_isPlaying && _listeningIcao != icao) {
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
    await _audioPlayer.stop();
      setState(() {
        _listeningIcao = null;
        _currentStreamName = null;
        _currentStreamUrl = null;
      });
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
          // Menu wyboru lotniska
          PopupMenuButton<String>(
            tooltip: 'Wybierz lotnisko',
            icon: const Icon(Icons.local_airport),
            onSelected: (icao) async {
              final airport = airports.firstWhereOrNull((a) => a.icao == icao);
              if (airport != null) {
                // Wycentruj mapę na wybranym lotnisku
                _mapController.move(airport.location, 11);
              }
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
          // Przycisk odświeżania - najczęściej używany
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież pozycje samolotów',
            onPressed: noAirportSelected ? null : fetchAircraftPositions,
          ),
          // Menu z pozostałymi opcjami
          PopupMenuButton<String>(
            tooltip: 'Więcej opcji',
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'flights':
                  if (!noAirportSelected) {
                    final result = await Navigator.of(context).push<Map<String, dynamic>>(
                      MaterialPageRoute(
                        builder: (context) =>
                            FlightsBoardScreen(initialAirport: _selectedIcao),
                      ),
                    );
                    
                    if (result != null && mounted) {
                      final lat = result['latitude'] as double;
                      final lon = result['longitude'] as double;
                      final icao24 = result['icao24'] as String;
                      final heading = result['heading'] as double? ?? 0.0;
                      
                      _mapController.move(LatLng(lat, lon), 12.0);
                      
                      final callsign = result['callsign'] as String?;
                      _trackedIcao24 = icao24;
                      _trackedCallsign = callsign;
                      _lastKnownPosition = LatLng(lat, lon);
                      _lastKnownHeading = heading;
                      
                      await fetchAircraftPositions();
                      _startLiveTracking(
                        icao24: icao24,
                        initialLat: lat,
                        initialLon: lon,
                        initialHeading: heading,
                        callsign: callsign,
                        markerIndex: _trackedMarkerIndex,
                      );
                    }
                  }
                  break;
                case 'airport_info':
                  if (!noAirportSelected) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AirportInfoScreen(airportIcao: _selectedIcao),
                      ),
                    );
                  }
                  break;
                case 'photos':
                  if (!noAirportSelected) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AircraftPhotosScreen(airportIcao: _selectedIcao),
                      ),
                    );
                  }
                  break;
                case 'streams':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StreamsManagementScreen(),
                    ),
                  );
                  break;
                case 'settings':
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  await _loadAirports();
                  break;
                case 'info':
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Informacje'),
                      content: const Text('Aplikacja TowerFlower - centrum informacji lotniskowej.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Zamknij'),
                        ),
                      ],
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'flights',
                enabled: !noAirportSelected,
                child: const Row(
                  children: [
                    Icon(Icons.flight_takeoff, size: 20),
                    SizedBox(width: 12),
                    Text('Loty'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'airport_info',
                enabled: !noAirportSelected,
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Informacje lotniskowe'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'photos',
                enabled: !noAirportSelected,
                child: const Row(
                  children: [
                    Icon(Icons.photo_camera, size: 20),
                    SizedBox(width: 12),
                    Text('Zdjęcia samolotów'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'streams',
                child: Row(
                  children: [
                    Icon(Icons.radio, size: 20),
                    SizedBox(width: 12),
                    Text('Moje streamy'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Ustawienia'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20),
                    SizedBox(width: 12),
                    Text('Informacje'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
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
              MarkerLayer(
                markers: [
                  ..._aircraftMarkers,
                  if (_trackedAircraftMarker != null) _trackedAircraftMarker!,
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton(
              heroTag: 'layer_toggle',
              mini: true,
              tooltip: _mapLayers[_currentLayerIndex].name,
              onPressed: () {
                setState(() {
                  _currentLayerIndex =
                      (_currentLayerIndex + 1) % _mapLayers.length;
                });
              },
              child: const Icon(Icons.layers, size: 20),
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
                // Pierwszy rząd - może się zawinąć do 2 rzędów na wąskich ekranach
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Wybrane lotnisko: ${_selectedIcao.isEmpty ? "Brak" : _selectedIcao}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: _isPlaying
                          ? _stopStream
                          : (hasStreamForSelected
                              ? () => _playLiveStreamForAirport(_selectedIcao)
                              : null),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 18),
                            const SizedBox(width: 4),
                            Text(_isPlaying ? 'Stop' : 'Odtwórz'),
                          ],
                        ),
                      ),
                    ),
                    if ((_isPlaying || _listeningIcao != null) && _listeningIcao != null && _listeningIcao!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        tooltip: 'Zmień stream',
                        onPressed: _changeStream,
                        iconSize: 24,
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Drugi rząd - może się zawinąć do 2 rzędów na wąskich ekranach
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      Icons.radio,
                      color: _isPlaying ? Colors.green : Colors.grey,
                      size: 18,
                    ),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 100,
                      ),
                      child: Text(
                        (_isPlaying || _listeningIcao != null)
                            ? '${_listeningIcao ?? _selectedIcao}${_currentStreamName != null && _currentStreamName!.isNotEmpty ? ' - $_currentStreamName' : ''}'
                            : 'Brak aktywnego nasłuchu',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (_isPlaying || _listeningIcao != null) ? Colors.green : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
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
