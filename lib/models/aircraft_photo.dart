import 'package:cloud_firestore/cloud_firestore.dart';

class AircraftPhoto {
  final String id;
  final String airportIcao;
  final String imageUrl;
  final String? aircraftRegistration;
  final String? flightNumber;
  final String? description;
  final String? uploadedBy;
  final String? uploadedByEmail;
  final DateTime uploadedAt;
  final int likes;

  AircraftPhoto({
    required this.id,
    required this.airportIcao,
    required this.imageUrl,
    this.aircraftRegistration,
    this.flightNumber,
    this.description,
    this.uploadedBy,
    this.uploadedByEmail,
    required this.uploadedAt,
    this.likes = 0,
  });

  factory AircraftPhoto.fromFirestore(Map<String, dynamic> data, String id) {
    return AircraftPhoto(
      id: id,
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
  }

  Map<String, dynamic> toFirestore() {
    return {
      'airportIcao': airportIcao,
      'imageUrl': imageUrl,
      'aircraftRegistration': aircraftRegistration,
      'flightNumber': flightNumber,
      'description': description,
      'uploadedBy': uploadedBy,
      'uploadedByEmail': uploadedByEmail,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'likes': likes,
    };
  }
}

