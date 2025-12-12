import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/airport.dart';
import '../models/airports_data.dart';
import '../services/firebase_service.dart';
import '../services/airport_search_service.dart';

class AirportsManagementScreen extends StatefulWidget {
  const AirportsManagementScreen({super.key});

  @override
  State<AirportsManagementScreen> createState() => _AirportsManagementScreenState();
}

class _AirportsManagementScreenState extends State<AirportsManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final AirportSearchService _searchService = AirportSearchService();
  List<Airport> _airports = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSearching = false;
  List<Airport> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadAirports();
  }

  Future<void> _loadAirports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Najpierw próbuj załadować z Firebase
      final firebaseAirports = await _firebaseService.getAirports();
      
      if (firebaseAirports.isNotEmpty) {
        setState(() {
          _airports = firebaseAirports;
        });
      } else {
        // Fallback do stałej listy
        setState(() {
          _airports = airports;
        });
      }
    } catch (e) {
      // W przypadku błędu użyj stałej listy
      setState(() {
        _airports = airports;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchAirports() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final query = _searchQuery.trim();
      
      // Jeśli query ma 4 znaki, traktuj jako kod ICAO
      if (query.length == 4) {
        final airport = await _searchService.searchAirportByIcao(query.toUpperCase());
        setState(() {
          _searchResults = airport != null ? [airport] : [];
        });
      } else {
        // Wyszukaj po nazwie
        final results = await _searchService.searchAirportsByName(query);
        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd wyszukiwania: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _addAirport(Airport airport) async {
    try {
      await _firebaseService.saveAirportData(airport);
      await _loadAirports();
      // Odśwież globalną listę lotnisk
      await loadAirports();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lotnisko ${airport.icao} zostało dodane'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd dodawania lotniska: $e')),
        );
      }
    }
  }

  Future<void> _showAddManualDialog() async {
    final icaoController = TextEditingController();
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dodaj lotnisko ręcznie'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: icaoController,
                decoration: const InputDecoration(
                  labelText: 'Kod ICAO *',
                  hintText: 'np. EPKK',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa lotniska *',
                  hintText: 'np. Kraków-Balice',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      decoration: const InputDecoration(
                        labelText: 'Szerokość geogr. *',
                        hintText: 'np. 50.0777',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: lonController,
                      decoration: const InputDecoration(
                        labelText: 'Długość geogr. *',
                        hintText: 'np. 19.7848',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () {
              final icao = icaoController.text.trim().toUpperCase();
              final name = nameController.text.trim();
              final lat = double.tryParse(latController.text.trim());
              final lon = double.tryParse(lonController.text.trim());

              if (icao.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kod ICAO musi mieć 4 znaki')),
                );
                return;
              }

              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nazwa lotniska jest wymagana')),
                );
                return;
              }

              if (lat == null || lon == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Współrzędne geograficzne są wymagane')),
                );
                return;
              }

              Navigator.of(context).pop(true);
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );

    if (result == true) {
      final icao = icaoController.text.trim().toUpperCase();
      final name = nameController.text.trim();
      final lat = double.parse(latController.text.trim());
      final lon = double.parse(lonController.text.trim());

      final airport = Airport(
        icao: icao,
        name: name,
        location: LatLng(lat, lon),
        liveStreamUrl: null,
      );

      await _addAirport(airport);
    }
  }

  Future<void> _deleteAirport(Airport airport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Usuń lotnisko'),
        content: Text('Czy na pewno chcesz usunąć lotnisko ${airport.icao} - ${airport.name}?'),
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
      try {
        // Usuń z Firebase
        await _firebaseService.firestore
            .collection('airports')
            .doc(airport.icao)
            .delete();
        
        await _loadAirports();
        // Odśwież globalną listę lotnisk
        await loadAirports();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lotnisko ${airport.icao} zostało usunięte'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd usuwania lotniska: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zarządzanie lotniskami'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Dodaj ręcznie',
            onPressed: _showAddManualDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Wyszukiwarka
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Wyszukaj lotnisko',
                    hintText: 'Wpisz kod ICAO (np. EPKK) lub nazwę',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    // Automatyczne wyszukiwanie po 500ms od ostatniego znaku
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_searchQuery == value && value.isNotEmpty) {
                        _searchAirports();
                      }
                    });
                  },
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),

          // Wyniki wyszukiwania lub lista lotnisk
          Expanded(
            child: _searchQuery.isNotEmpty && _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildAirportsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final airport = _searchResults[index];
        final alreadyAdded = _airports.any((a) => a.icao == airport.icao);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.local_airport),
            title: Text(airport.icao),
            subtitle: Text(
              '${airport.name}\n'
              '${airport.location.latitude.toStringAsFixed(4)}, ${airport.location.longitude.toStringAsFixed(4)}',
            ),
            trailing: alreadyAdded
                ? const Icon(Icons.check, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.add_circle),
                    color: Colors.blue,
                    onPressed: () => _addAirport(airport),
                  ),
            onTap: alreadyAdded
                ? null
                : () => _addAirport(airport),
          ),
        );
      },
    );
  }

  Widget _buildAirportsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_airports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_airport, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Brak lotnisk',
              style: TextStyle(color: Colors.grey[600], fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Dodaj lotnisko używając wyszukiwarki lub przycisku "Dodaj ręcznie"',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _airports.length,
      itemBuilder: (context, index) {
        final airport = _airports[index];
        final isDefault = airports.any((a) => a.icao == airport.icao);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.local_airport),
            title: Text(airport.icao),
            subtitle: Text(
              '${airport.name}\n'
              '${airport.location.latitude.toStringAsFixed(4)}, ${airport.location.longitude.toStringAsFixed(4)}',
            ),
            trailing: isDefault
                ? const Tooltip(
                    message: 'Lotnisko domyślne',
                    child: Icon(Icons.lock, color: Colors.grey),
                  )
                : IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () => _deleteAirport(airport),
                  ),
          ),
        );
      },
    );
  }
}

