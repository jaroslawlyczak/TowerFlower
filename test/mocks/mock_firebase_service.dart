import 'package:cloud_firestore/cloud_firestore.dart';

/// Mock FirebaseService dla testów
/// Uwaga: FirebaseService jest singletonem, więc nie możemy go łatwo zmockować
/// W testach używamy prawdziwego FirebaseService, ale z pustymi danymi
class MockFirebaseServiceHelper {
  /// Pomocnicza metoda do resetowania stanu FirebaseService w testach
  static void setupMockData() {
    // W testach FirebaseService będzie używał prawdziwego Firebase
    // ale z pustymi kolekcjami, więc nie będzie błędów
  }

  /// Pomocnicza metoda do sprawdzania czy Firebase jest dostępny
  static bool isFirebaseAvailable() {
    try {
      // Sprawdź czy Firebase jest zainicjalizowany
      FirebaseFirestore.instance;
      return true;
    } catch (e) {
      return false;
    }
  }
}
