import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/aircraft_photo.dart';
import '../services/firebase_service.dart';

class MyPhotosScreen extends StatefulWidget {
  const MyPhotosScreen({super.key});

  @override
  State<MyPhotosScreen> createState() => _MyPhotosScreenState();
}

class _MyPhotosScreenState extends State<MyPhotosScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;
    
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Moje zdjęcia'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Musisz być zalogowany',
                style: TextStyle(color: Colors.grey[600], fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Zaloguj się, aby zobaczyć swoje zdjęcia',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Zaloguj się'),
                onPressed: () {
                  Navigator.of(context).pushNamed('/auth');
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje zdjęcia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Odśwież',
            onPressed: () {
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AircraftPhoto>>(
        stream: _firebaseService.getMyAircraftPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Błąd w StreamBuilder moich zdjęć: ${snapshot.error}');
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
          debugPrint('Załadowano ${photos.length} moich zdjęć');

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
                    'Nie dodałeś jeszcze żadnych zdjęć',
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
              return GestureDetector(
                onTap: () => _showPhotoDetails(photo),
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
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (photo.aircraftRegistration != null)
                                Text(
                                  photo.aircraftRegistration!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (photo.flightNumber != null)
                                Text(
                                  photo.flightNumber!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                photo.airportIcao,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
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
    );
  }

  void _showPhotoDetails(AircraftPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (detailsContext) => _PhotoDetailsScreen(
          photo: photo,
          isOwner: true,
          firebaseService: _firebaseService,
          onDelete: (BuildContext deleteContext) async {
            try {
              await _firebaseService.deleteAircraftPhoto(photo.id);
              if (!deleteContext.mounted) return;
              ScaffoldMessenger.of(deleteContext).showSnackBar(
                const SnackBar(
                  content: Text('Zdjęcie zostało usunięte'),
                  backgroundColor: Colors.green,
                ),
              );
              if (!deleteContext.mounted) return;
              Navigator.of(deleteContext).pop();
            } catch (e) {
              if (!deleteContext.mounted) return;
              ScaffoldMessenger.of(deleteContext).showSnackBar(
                SnackBar(
                  content: Text('Błąd podczas usuwania zdjęcia: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

class _PhotoDetailsScreen extends StatefulWidget {
  final AircraftPhoto photo;
  final bool isOwner;
  final FirebaseService firebaseService;
  final Future<void> Function(BuildContext) onDelete;

  const _PhotoDetailsScreen({
    required this.photo,
    required this.isOwner,
    required this.firebaseService,
    required this.onDelete,
  });

  @override
  State<_PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<_PhotoDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Szczegóły zdjęcia'),
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Usuń zdjęcie'),
                    content: const Text('Czy na pewno chcesz usunąć to zdjęcie?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Anuluj'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Usuń'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  if (!mounted) return;
                  // ignore: use_build_context_synchronously
                  await widget.onDelete(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CachedNetworkImage(
              imageUrl: widget.photo.imageUrl,
              fit: BoxFit.cover,
              height: 300,
              placeholder: (context, url) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.error, size: 64),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.photo.aircraftRegistration != null) ...[
                    const Text(
                      'Rejestracja samolotu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.photo.aircraftRegistration!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.photo.flightNumber != null) ...[
                    const Text(
                      'Numer lotu',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.photo.flightNumber!,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Lotnisko',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.photo.airportIcao,
                    style: const TextStyle(fontSize: 18),
                  ),
                  if (widget.photo.description != null && widget.photo.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Opis',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.photo.description!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Data dodania',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.photo.uploadedAt.day}.${widget.photo.uploadedAt.month}.${widget.photo.uploadedAt.year} ${widget.photo.uploadedAt.hour.toString().padLeft(2, '0')}:${widget.photo.uploadedAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.photo.uploadedByEmail != null) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Dodane przez',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.photo.uploadedByEmail!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Colors.red, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.photo.likes} polubień',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

