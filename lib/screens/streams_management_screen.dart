import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/firebase_service.dart';
import '../models/airports_data.dart';

class StreamsManagementScreen extends StatefulWidget {
  const StreamsManagementScreen({super.key});

  @override
  State<StreamsManagementScreen> createState() => _StreamsManagementScreenState();
}

class _StreamsManagementScreenState extends State<StreamsManagementScreen> {
  final _firebaseService = FirebaseService();
  List<Map<String, dynamic>> _userStreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStreams();
  }

  Future<void> _loadUserStreams() async {
    try {
      final streams = await _firebaseService.getAllUserStreams();
      setState(() {
        _userStreams = streams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania streamów: $e')),
        );
      }
    }
  }

  Future<void> _addOrEditStream(String airportIcao, {Map<String, dynamic>? existingStream}) async {
    final streamNameController = TextEditingController(
      text: existingStream?['streamName'] ?? '',
    );
    final streamUrlController = TextEditingController(
      text: existingStream?['streamUrl'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingStream != null ? 'Edytuj stream' : 'Dodaj stream'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lotnisko: $airportIcao'),
            const SizedBox(height: 16),
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
            child: Text(existingStream != null ? 'Zapisz' : 'Dodaj'),
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
          streamId: existingStream?['id'] as String?,
        );

        await _loadUserStreams();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(existingStream != null 
                  ? 'Stream został zaktualizowany' 
                  : 'Stream został dodany'),
            ),
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

  Future<void> _deleteStream(String streamId, String airportIcao) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń stream'),
        content: Text('Czy na pewno chcesz usunąć ten stream dla lotniska $airportIcao?'),
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

    if (result == true) {
      try {
        await _firebaseService.deleteUserStream(streamId);
        await _loadUserStreams();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Stream został usunięty')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd usuwania streamu: $e')),
          );
        }
      }
    }
  }

  String _getAirportName(String icao) {
    final airport = airports.firstWhere(
      (a) => a.icao == icao,
      orElse: () => Airport(icao: icao, name: icao, location: const LatLng(0, 0)),
    );
    return airport.name;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje streamy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserStreams,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Zarządzanie streamami',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _firebaseService.currentUser == null
                        ? 'Dodaj tymczasowe linki do streamów radiowych lotnisk. '
                          'Streamy będą dostępne tylko podczas tej sesji.'
                        : 'Dodaj swoje własne linki do streamów radiowych lotnisk. '
                          'Streamy będą zapisane w Twoim koncie.',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Liczba streamów: ${_userStreams.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Streams list
          Expanded(
            child: _userStreams.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radio, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Brak streamów',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dodaj swój pierwszy stream',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _userStreams.length,
                    itemBuilder: (context, index) {
                      final stream = _userStreams[index];
                      final streamId = stream['id'] as String? ?? '';
                      final airportIcao = stream['airportIcao'] as String;
                      final streamName = stream['streamName'] as String?;
                      final streamUrl = stream['streamUrl'] as String;

                      final isTemporary = stream['isTemporary'] == true;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            isTemporary ? Icons.radio_outlined : Icons.radio,
                            color: isTemporary ? Colors.orange : Colors.blue,
                          ),
                          title: Row(
                            children: [
                              Expanded(child: Text(streamName ?? 'Stream $airportIcao')),
                              if (isTemporary)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Tymczasowy',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lotnisko: ${_getAirportName(airportIcao)} ($airportIcao)'),
                              const SizedBox(height: 4),
                              Text(
                                streamUrl,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _addOrEditStream(airportIcao, existingStream: stream);
                                  break;
                                case 'delete':
                                  _deleteStream(streamId, airportIcao);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edytuj'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Usuń', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStreamDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddStreamDialog() async {
    final selectedAirport = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wybierz lotnisko'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: airports.length,
            itemBuilder: (context, index) {
              final airport = airports[index];
              final streamCount = _userStreams.where((s) => s['airportIcao'] == airport.icao).length;
              
              return ListTile(
                leading: Icon(
                  streamCount > 0 ? Icons.radio : Icons.radio_outlined,
                  color: streamCount > 0 ? Colors.green : Colors.grey,
                ),
                title: Text(airport.name),
                subtitle: Text(airport.icao),
                trailing: streamCount > 0 
                    ? Text('$streamCount ${streamCount == 1 ? 'stream' : 'streamy'}', 
                        style: const TextStyle(color: Colors.green, fontSize: 12))
                    : null,
                onTap: () => Navigator.of(context).pop(airport.icao),
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

    if (selectedAirport != null) {
      await _addOrEditStream(selectedAirport);
    }
  }
}
