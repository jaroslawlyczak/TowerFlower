// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import '../models/airport_flight.dart';
import '../services/airport_info_service.dart';
import '../models/airports_data.dart';
import 'aircraft_photos_screen.dart';

class AirportInfoScreen extends StatefulWidget {
  final String airportIcao;

  const AirportInfoScreen({super.key, required this.airportIcao});

  @override
  _AirportInfoScreenState createState() => _AirportInfoScreenState();
}

class _AirportInfoScreenState extends State<AirportInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AirportInfoService _airportInfoService = AirportInfoService();
  
  Future<List<AirportFlight>>? _arrivalsFuture;
  Future<List<AirportFlight>>? _departuresFuture;
  
  int _hoursRange = 3; // Domyślnie 3 godziny, żeby nie wycinać bliskich lotów
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      setState(() {
        // Używamy Aviationstack API z domyślnym kluczem i filtrowaniem czasowym
        _arrivalsFuture = _airportInfoService.fetchArrivals(widget.airportIcao, hoursRange: _hoursRange);
        _departuresFuture = _airportInfoService.fetchDepartures(widget.airportIcao, hoursRange: _hoursRange);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd ładowania danych: $e';
      });
    }
  }

  Future<void> _showTimeRangeDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zakres czasowy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Wybierz zakres godzin do wyświetlenia:'),
            const SizedBox(height: 16),
            ...List.generate(6, (index) {
              final hours = index + 1;
              return RadioListTile<int>(
                title: Text('$hours ${hours == 1 ? 'godzina' : hours < 5 ? 'godziny' : 'godzin'}'),
                value: hours,
                groupValue: _hoursRange,
                onChanged: (value) {
                  Navigator.of(context).pop(value);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anuluj'),
          ),
        ],
      ),
    );

    if (result != null && result != _hoursRange) {
      setState(() {
        _hoursRange = result;
      });
      _loadData();
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Brak';
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Brak statusu';
    final s = status.toLowerCase();
    if (s.contains('scheduled')) return 'Oczekiwany';
    if (s.contains('active')) return 'W locie';
    if (s.contains('landed') || s.contains('arrived')) return 'Wylądował';
    if (s.contains('cancel')) return 'Anulowany';
    if (s.contains('delayed') || s.contains('late')) return 'Opóźniony';
    if (s.contains('departed')) return 'Wystartował';
    return status;
  }

  /// Zwraca opis i czas do wyświetlenia zależnie od statusu i kierunku lotu.
  /// Priorytet: actual (jeśli landed/departed) -> estimated -> scheduled.
  (String label, DateTime? time) _displayTime(AirportFlight flight, bool isArrival) {
    final status = flight.status?.toLowerCase() ?? '';
    final isLanded = status.contains('landed') || status.contains('arrived');
    final isDeparted = status.contains('departed');
    final now = DateTime.now();
    const int landedThresholdMinutes = 5;

    if (isArrival) {
      if (isLanded || flight.actualTime != null) {
        return ('Lądował', flight.actualTime ?? flight.estimatedTime ?? flight.scheduledTime);
      }
      // Heurystyka: brak actual/estimated, czas planowany minął > threshold
      if (flight.scheduledTime != null) {
        final diff = now.difference(flight.scheduledTime!);
        if (diff.inMinutes > landedThresholdMinutes) {
          return ('Lądował (szac.)', flight.scheduledTime);
        }
      }
      if (flight.estimatedTime != null) {
        return ('Oczekiwany', flight.estimatedTime);
      }
      return ('Planowany', flight.scheduledTime);
    } else {
      if (isDeparted || flight.actualTime != null) {
        return ('Wystartował', flight.actualTime ?? flight.estimatedTime ?? flight.scheduledTime);
      }
      if (flight.scheduledTime != null) {
        final diff = now.difference(flight.scheduledTime!);
        if (diff.inMinutes > landedThresholdMinutes) {
          return ('Wystartował (szac.)', flight.scheduledTime);
        }
      }
      if (flight.estimatedTime != null) {
        return ('Oczekiwany', flight.estimatedTime);
      }
      return ('Planowany', flight.scheduledTime);
    }
  }

  String _getStatusColor(String? status) {
    if (status == null) return 'grey';
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('on time') || lowerStatus.contains('scheduled')) {
      return 'green';
    } else if (lowerStatus.contains('delayed') || lowerStatus.contains('late')) {
      return 'orange';
    } else if (lowerStatus.contains('cancelled') || lowerStatus.contains('canceled')) {
      return 'red';
    } else if (lowerStatus.contains('landed') || lowerStatus.contains('departed')) {
      return 'blue';
    }
    return 'grey';
  }

  Widget _buildFlightList(List<AirportFlight> flights, bool isArrival) {
    if (flights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flight,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Brak ${isArrival ? 'przylotów' : 'odlotów'}',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: flights.length,
        itemBuilder: (context, index) {
          final flight = flights[index];
          final statusColor = _getStatusColor(flight.status);
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isArrival ? Icons.flight_land : Icons.flight_takeoff,
                    color: _getStatusColorIcon(statusColor),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (_) {
                    final (label, time) = _displayTime(flight, isArrival);
                    return Text(
                      _formatDateTime(time),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ],
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    flight.flightNumber ?? 'Brak numeru',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (flight.codesharedNumber != null)
                    Text(
                      'Operated by: ${flight.codesharedNumber!}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (flight.airline != null)
                    Text(
                      'Linia: ${flight.airline}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (isArrival && flight.origin != null)
                    Text(
                      'Z: ${flight.origin}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (!isArrival && flight.destination != null)
                    Text(
                      'Do: ${flight.destination}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (flight.gate != null)
                    Text(
                      'Bramka: ${flight.gate}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  if (flight.terminal != null)
                    Text(
                      'Terminal: ${flight.terminal}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColorBackground(statusColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _statusLabel(flight.status),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Builder(builder: (_) {
                    final (label, time) = _displayTime(flight, isArrival);
                    if (time == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '$label: ${_formatDateTime(time)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColorIcon(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColorBackground(String colorName) {
    switch (colorName) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Airport airport = airports.firstWhere(
      (a) => a.icao == widget.airportIcao,
      orElse: () => airports.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informacje lotniskowe'),
            Text(
              airport.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.flight_land),
              text: 'Przyloty',
            ),
            Tab(
              icon: Icon(Icons.flight_takeoff),
              text: 'Odloty',
            ),
            Tab(
              icon: Icon(Icons.photo_camera),
              text: 'Zdjęcia',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: _showTimeRangeDialog,
            tooltip: 'Zakres czasowy (${_hoursRange}h)',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Odśwież',
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Spróbuj ponownie'),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Uwaga: Aby korzystać z tej funkcji, musisz dodać klucz API w ustawieniach aplikacji.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<List<AirportFlight>>(
                  future: _arrivalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Błąd: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      );
                    }
                    final arrivals = snapshot.data ?? [];
                    return _buildFlightList(arrivals, true);
                  },
                ),
                FutureBuilder<List<AirportFlight>>(
                  future: _departuresFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Błąd: ${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
                      );
                    }
                    final departures = snapshot.data ?? [];
                    return _buildFlightList(departures, false);
                  },
                ),
                AircraftPhotosScreen(airportIcao: widget.airportIcao),
              ],
            ),
    );
  }
}

