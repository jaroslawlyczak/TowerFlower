// ignore_for_file: library_private_types_in_public_api, unnecessary_nullable_for_final_variable_declarations

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/fligth.dart';
import '../models/airports_data.dart';

class FlightsBoardScreen extends StatefulWidget {
  final String initialAirport;
  const FlightsBoardScreen({super.key, required this.initialAirport});

  @override
  _FlightsBoardScreenState createState() => _FlightsBoardScreenState();
}

class _FlightsBoardScreenState extends State<FlightsBoardScreen> {
  late Future<List<Flight>> _flightsFuture;

  @override
  void initState() {
    super.initState();
    _flightsFuture = fetchFlightsForAirport(widget.initialAirport);
  }

  Future<List<Flight>> fetchFlightsForAirport(String airportIcao) async {
    final Airport? airport = airports.firstWhere(
      (a) => a.icao == airportIcao,
      orElse: () => throw Exception('Nie znaleziono lotniska $airportIcao'),
    );

    const double delta = 0.3;
    final bounds = {
      'lamin': airport!.location.latitude - delta,
      'lomin': airport.location.longitude - delta,
      'lamax': airport.location.latitude + delta,
      'lomax': airport.location.longitude + delta,
    };

    final url = Uri.parse(
      'https://opensky-network.org/api/states/all'
      '?lamin=${bounds['lamin']}&lomin=${bounds['lomin']}&lamax=${bounds['lamax']}&lomax=${bounds['lomax']}',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Błąd pobierania danych lotów');
    }

    final data = json.decode(response.body);
    final List<dynamic> states = data['states'] ?? [];

    return states.map<Flight>((state) => Flight.fromJson(state)).where((f) => f.latitude != 0 && f.longitude != 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loty w okolicy ${widget.initialAirport}'),
      ),
      body: FutureBuilder<List<Flight>>(
        future: _flightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Błąd: ${snapshot.error}'));
          }
          final flights = snapshot.data ?? [];
          if (flights.isEmpty) {
            return const Center(child: Text('Brak lotów w okolicy'));
          }
          return ListView.builder(
            itemCount: flights.length,
            itemBuilder: (context, index) {
              final flight = flights[index];
              return ListTile(
                leading: const Icon(Icons.flight),
                title: Text(flight.callsign),
                subtitle: Text('Kraj: ${flight.originCountry}\n'
                    'Pozycja: ${flight.latitude.toStringAsFixed(4)}, ${flight.longitude.toStringAsFixed(4)}\n'
                    'Kierunek: ${flight.heading.toStringAsFixed(0)}°'),
                onTap: () {
                  // Navigate back to map screen with flight data
                  Navigator.of(context).pop({
                    'icao24': flight.icao24,
                    'latitude': flight.latitude,
                    'longitude': flight.longitude,
                    'callsign': flight.callsign,
                    'heading': flight.heading,
                    'originCountry': flight.originCountry,
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}
