import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/aircraft_photo.dart';
import '../services/firebase_service.dart';

class AircraftPhotosScreen extends StatefulWidget {
  final String airportIcao;

  const AircraftPhotosScreen({super.key, required this.airportIcao});

  @override
  State<AircraftPhotosScreen> createState() => _AircraftPhotosScreenState();
}

class _AircraftPhotosScreenState extends State<AircraftPhotosScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  Future<void> _showAddPhotoDialog() async {
    if (_firebaseService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Musisz być zalogowany, aby dodać zdjęcie'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aircraftRegistrationController = TextEditingController();
    final flightNumberController = TextEditingController();
    final descriptionController = TextEditingController();
    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Dodaj zdjęcie samolotu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectedImageBytes != null)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        selectedImageBytes!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.camera,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedImage = image;
                            selectedImageBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Aparat'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final image = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                        );
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setDialogState(() {
                            selectedImage = image;
                            selectedImageBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galeria'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: aircraftRegistrationController,
                  decoration: const InputDecoration(
                    labelText: 'Rejestracja samolotu (opcjonalnie)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: flightNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numer lotu (opcjonalnie)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Opis (opcjonalnie)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: selectedImage == null || selectedImageBytes == null
                  ? null
                  : () async {
                      Navigator.of(context).pop();
                      await _uploadPhoto(
                        selectedImage!,
                        selectedImageBytes!,
                        aircraftRegistrationController.text.trim().isEmpty
                            ? null
                            : aircraftRegistrationController.text.trim(),
                        flightNumberController.text.trim().isEmpty
                            ? null
                            : flightNumberController.text.trim(),
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      );
                    },
              child: const Text('Dodaj'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(
    XFile imageFile,
    Uint8List imageBytes,
    String? aircraftRegistration,
    String? flightNumber,
    String? description,
  ) async {
    setState(() {
      _isUploading = true;
    });

    try {
      await _firebaseService.uploadAircraftPhoto(
        airportIcao: widget.airportIcao,
        imageFile: imageFile,
        imageBytes: imageBytes,
        aircraftRegistration: aircraftRegistration,
        flightNumber: flightNumber,
        description: description,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zdjęcie zostało dodane!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas dodawania zdjęcia: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deletePhoto(AircraftPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usunąć zdjęcie?'),
        content: const Text('Czy na pewno chcesz usunąć to zdjęcie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.deleteAircraftPhoto(photo.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Zdjęcie zostało usunięte'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Błąd podczas usuwania zdjęcia: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _firebaseService.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zdjęcia samolotów'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: () {
              setState(() {
                // Wymuś odświeżenie streamu
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AircraftPhoto>>(
        stream: _firebaseService.getAircraftPhotos(widget.airportIcao),
        builder: (context, snapshot) {
          // Debug - wyświetl informacje o stanie
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Błąd w StreamBuilder zdjęć: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Błąd: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Spróbuj ponownie'),
                    onPressed: () {
                      setState(() {});
                    },
                  ),
                ],
              ),
            );
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Brak zdjęć',
                    style: TextStyle(color: Colors.grey[600], fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLoggedIn
                        ? 'Dodaj pierwsze zdjęcie!'
                        : 'Zaloguj się, aby dodać zdjęcie',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final isOwner = isLoggedIn &&
                  _firebaseService.currentUser!.uid == photo.uploadedBy;

              return GestureDetector(
                onTap: () => _showPhotoDetails(photo, isOwner),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: photo.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (photo.flightNumber != null)
                                Text(
                                  photo.flightNumber!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              if (photo.aircraftRegistration != null)
                                Text(
                                  photo.aircraftRegistration!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${photo.likes}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isLoggedIn
          ? FloatingActionButton(
              onPressed: _isUploading ? null : _showAddPhotoDialog,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.add_photo_alternate),
            )
          : null,
    );
  }

  void _showPhotoDetails(AircraftPhoto photo, bool isOwner) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PhotoDetailsScreen(
          photo: photo,
          isOwner: isOwner,
          firebaseService: _firebaseService,
          onDelete: () => _deletePhoto(photo),
        ),
      ),
    );
  }

}

class _PhotoDetailsScreen extends StatelessWidget {
  final AircraftPhoto photo;
  final bool isOwner;
  final FirebaseService firebaseService;
  final VoidCallback onDelete;

  const _PhotoDetailsScreen({
    required this.photo,
    required this.isOwner,
    required this.firebaseService,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły zdjęcia'),
      ),
      body: StreamBuilder<List<AircraftPhoto>>(
        stream: firebaseService.getAircraftPhotos(photo.airportIcao),
        builder: (context, snapshot) {
          // Znajdź aktualne dane zdjęcia ze streamu
          final currentPhoto = snapshot.hasData
              ? snapshot.data!.firstWhere(
                  (p) => p.id == photo.id,
                  orElse: () => photo,
                )
              : photo;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 300,
                  child: CachedNetworkImage(
                    imageUrl: currentPhoto.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentPhoto.flightNumber != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.flight, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                currentPhoto.flightNumber!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (currentPhoto.aircraftRegistration != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.airplanemode_active, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                currentPhoto.aircraftRegistration!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      if (currentPhoto.description != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(currentPhoto.description!),
                        ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.favorite_border),
                                onPressed: () {
                                  firebaseService.likeAircraftPhoto(currentPhoto.id);
                                },
                              ),
                              Text(
                                '${currentPhoto.likes}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          if (isOwner)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.of(context).pop();
                                onDelete();
                              },
                            ),
                        ],
                      ),
                      if (currentPhoto.uploadedByEmail != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Dodane przez: ${currentPhoto.uploadedByEmail}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      Text(
                        'Data: ${_formatDate(currentPhoto.uploadedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

