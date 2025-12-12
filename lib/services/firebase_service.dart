import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../models/airport.dart';
import '../models/aircraft_photo.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // Getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseRemoteConfig get remoteConfig => _remoteConfig;

  // User management
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Remote Config
  Future<void> initializeRemoteConfig() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    
    await _remoteConfig.fetchAndActivate();
  }

  // Authentication methods
  Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _analytics.logLogin(loginMethod: 'email');
      return credential;
    } catch (e) {
      await _analytics.logEvent(
        name: 'auth_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email, 
    String password
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _analytics.logSignUp(signUpMethod: 'email');
      return credential;
    } catch (e) {
      await _analytics.logEvent(
        name: 'auth_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _analytics.logEvent(name: 'user_signout');
  }

  // User preferences
  Future<void> saveUserPreferences({
    String? favoriteAirport,
    bool? notificationsEnabled,
    String? language,
  }) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set({
        'favoriteAirport': favoriteAirport,
        'notificationsEnabled': notificationsEnabled ?? true,
        'language': language ?? 'pl',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _analytics.logEvent(
        name: 'user_preferences_updated',
        parameters: {
          'favorite_airport': favoriteAirport ?? '',
          'notifications_enabled': (notificationsEnabled ?? true) ? 'true' : 'false',
          'language': language ?? 'pl',
        },
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserPreferences() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      return doc.data();
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      return null;
    }
  }

  // API Key management
  Future<void> saveApiKeyToFirebase(String apiKey) async {
    if (currentUser == null) {
      throw Exception('Musisz być zalogowany, aby zapisać klucz API w Firebase');
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set({
        'aviationstackApiKey': apiKey,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _analytics.logEvent(
        name: 'api_key_saved_firebase',
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<String?> getApiKeyFromFirebase() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      final data = doc.data();
      return data?['aviationstackApiKey'] as String?;
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      return null;
    }
  }

  // Flight tracking data
  Future<void> saveFlightTracking({
    required String icao24,
    required String callsign,
    required String airport,
    required double latitude,
    required double longitude,
    required double heading,
  }) async {
    try {
      await _firestore.collection('flight_tracking').add({
        'icao24': icao24,
        'callsign': callsign,
        'airport': airport,
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser?.uid,
      });

      await _analytics.logEvent(
        name: 'flight_tracked',
        parameters: {
          'callsign': callsign,
          'airport': airport,
          'icao24': icao24,
        },
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  // Temporary streams for non-authenticated users (stored locally)
  static final Map<String, Map<String, dynamic>> _temporaryStreams = {};

  // User stream management
  Future<String> saveUserStream({
    required String airportIcao,
    required String streamUrl,
    String? streamName,
    String? streamId, // Opcjonalne ID dla edycji istniejącego streamu
  }) async {
    if (currentUser == null) {
      // Save as temporary stream for non-authenticated users
      // Używamy timestamp jako ID dla tymczasowych streamów
      final tempId = DateTime.now().millisecondsSinceEpoch.toString();
      _temporaryStreams[tempId] = {
        'id': tempId,
        'airportIcao': airportIcao,
        'streamUrl': streamUrl,
        'streamName': streamName ?? 'Stream $airportIcao',
        'isTemporary': true,
        'createdAt': DateTime.now().toIso8601String(),
      };
      return tempId;
    }

    try {
      final streamData = {
        'airportIcao': airportIcao,
        'streamUrl': streamUrl,
        'streamName': streamName ?? 'Stream $airportIcao',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      String docId;
      if (streamId != null) {
        // Edycja istniejącego streamu
        docId = streamId;
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('streams')
            .doc(streamId)
            .update(streamData);
      } else {
        // Tworzenie nowego streamu
        final docRef = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('streams')
            .add({
          ...streamData,
          'createdAt': FieldValue.serverTimestamp(),
        });
        docId = docRef.id;
      }

      await _analytics.logEvent(
        name: 'user_stream_saved',
        parameters: {
          'airport_icao': airportIcao,
          'has_stream_name': streamName != null ? 'true' : 'false',
          'is_edit': streamId != null ? 'true' : 'false',
        },
      );

      return docId;
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> deleteUserStream(String streamId) async {
    if (currentUser == null) {
      // Remove temporary stream
      _temporaryStreams.remove(streamId);
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('streams')
          .doc(streamId)
          .delete();

      await _analytics.logEvent(
        name: 'user_stream_deleted',
        parameters: {'stream_id': streamId},
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserStreamsForAirport(String airportIcao) async {
    if (currentUser == null) {
      // Return temporary streams for non-authenticated users
      return _temporaryStreams.values
          .where((stream) => stream['airportIcao'] == airportIcao)
          .toList();
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('streams')
          .where('airportIcao', isEqualTo: airportIcao)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      return [];
    }
  }

  // Zachowana dla kompatybilności wstecznej - zwraca pierwszy stream dla lotniska
  Future<Map<String, dynamic>?> getUserStream(String airportIcao) async {
    final streams = await getUserStreamsForAirport(airportIcao);
    return streams.isNotEmpty ? streams.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllUserStreams() async {
    if (currentUser == null) {
      // Return temporary streams for non-authenticated users
      return _temporaryStreams.values.toList();
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('streams')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      return [];
    }
  }

  // Airport data management
  Future<void> saveAirportData(Airport airport) async {
    try {
      await _firestore
          .collection('airports')
          .doc(airport.icao)
          .set({
        'icao': airport.icao,
        'name': airport.name,
        'location': GeoPoint(
          airport.location.latitude,
          airport.location.longitude,
        ),
        'liveStreamUrl': airport.liveStreamUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'airport_data_saved',
        parameters: {'icao': airport.icao},
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<List<Airport>> getAirports() async {
    try {
      final snapshot = await _firestore.collection('airports').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final location = data['location'] as GeoPoint;
        
        return Airport(
          icao: data['icao'],
          name: data['name'],
          location: LatLng(location.latitude, location.longitude),
          liveStreamUrl: data['liveStreamUrl'],
        );
      }).toList();
    } catch (e) {
      await _analytics.logEvent(
        name: 'firestore_error',
        parameters: {'error': e.toString()},
      );
      return [];
    }
  }

  // Analytics helpers
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> logCustomEvent(String eventName, Map<String, Object> parameters) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
  }

  // Remote Config helpers
  String getString(String key, {String defaultValue = ''}) {
    return _remoteConfig.getString(key).isEmpty 
        ? defaultValue 
        : _remoteConfig.getString(key);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _remoteConfig.getBool(key);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _remoteConfig.getInt(key);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _remoteConfig.getDouble(key);
  }

  // Aircraft photos management
  Future<String> uploadAircraftPhoto({
    required String airportIcao,
    required XFile imageFile,
    required Uint8List imageBytes,
    String? aircraftRegistration,
    String? flightNumber,
    String? description,
  }) async {
    if (currentUser == null) {
      throw Exception('Musisz być zalogowany, aby dodać zdjęcie');
    }

    try {
      // Upload image to Firebase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      final ref = _storage.ref().child('aircraft_photos').child(airportIcao).child(fileName);
      
      // Use putData for web compatibility, putFile for other platforms
      if (kIsWeb) {
        await ref.putData(imageBytes);
      } else {
        await ref.putFile(File(imageFile.path));
      }
      final imageUrl = await ref.getDownloadURL();

      // Save metadata to Firestore
      final photoData = {
        'airportIcao': airportIcao,
        'imageUrl': imageUrl,
        'aircraftRegistration': aircraftRegistration,
        'flightNumber': flightNumber,
        'description': description,
        'uploadedBy': currentUser!.uid,
        'uploadedByEmail': currentUser!.email,
        'uploadedAt': FieldValue.serverTimestamp(),
        'likes': 0,
      };

      final docRef = await _firestore.collection('aircraft_photos').add(photoData);

      await _analytics.logEvent(
        name: 'aircraft_photo_uploaded',
        parameters: {
          'airport_icao': airportIcao,
          'has_registration': aircraftRegistration != null ? 'true' : 'false',
          'has_flight_number': flightNumber != null ? 'true' : 'false',
        },
      );

      return docRef.id;
    } catch (e) {
      await _analytics.logEvent(
        name: 'aircraft_photo_upload_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Stream<List<AircraftPhoto>> getAircraftPhotos(String airportIcao) {
    return _firestore
        .collection('aircraft_photos')
        .where('airportIcao', isEqualTo: airportIcao)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AircraftPhoto(
          id: doc.id,
          airportIcao: data['airportIcao'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          aircraftRegistration: data['aircraftRegistration'],
          flightNumber: data['flightNumber'],
          description: data['description'],
          uploadedBy: data['uploadedBy'],
          uploadedByEmail: data['uploadedByEmail'],
          uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likes: data['likes'] ?? 0,
        );
      }).toList();
    });
  }

  /// Pobiera wszystkie zdjęcia dodane przez aktualnie zalogowanego użytkownika
  Stream<List<AircraftPhoto>> getMyAircraftPhotos() {
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('aircraft_photos')
        .where('uploadedBy', isEqualTo: currentUser!.uid)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AircraftPhoto(
          id: doc.id,
          airportIcao: data['airportIcao'] ?? '',
          imageUrl: data['imageUrl'] ?? '',
          aircraftRegistration: data['aircraftRegistration'],
          flightNumber: data['flightNumber'],
          description: data['description'],
          uploadedBy: data['uploadedBy'],
          uploadedByEmail: data['uploadedByEmail'],
          uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          likes: data['likes'] ?? 0,
        );
      }).toList();
    });
  }

  Future<void> deleteAircraftPhoto(String photoId) async {
    if (currentUser == null) {
      throw Exception('Musisz być zalogowany, aby usunąć zdjęcie');
    }

    try {
      final doc = await _firestore.collection('aircraft_photos').doc(photoId).get();
      if (!doc.exists) {
        throw Exception('Zdjęcie nie istnieje');
      }

      final data = doc.data()!;
      if (data['uploadedBy'] != currentUser!.uid) {
        throw Exception('Możesz usunąć tylko swoje zdjęcia');
      }

      // Delete from Storage
      final imageUrl = data['imageUrl'] as String;
      if (imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          // Ignore storage errors, continue with Firestore deletion
        }
      }

      // Delete from Firestore
      await _firestore.collection('aircraft_photos').doc(photoId).delete();

      await _analytics.logEvent(
        name: 'aircraft_photo_deleted',
        parameters: {'photo_id': photoId},
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'aircraft_photo_delete_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }

  Future<void> likeAircraftPhoto(String photoId) async {
    try {
      await _firestore.collection('aircraft_photos').doc(photoId).update({
        'likes': FieldValue.increment(1),
      });

      await _analytics.logEvent(
        name: 'aircraft_photo_liked',
        parameters: {'photo_id': photoId},
      );
    } catch (e) {
      await _analytics.logEvent(
        name: 'aircraft_photo_like_error',
        parameters: {'error': e.toString()},
      );
      rethrow;
    }
  }
}
