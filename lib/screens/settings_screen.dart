import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
// import '../models/airports_data.dart'; // Przygotowanie na przyszłość - ulubione lotnisko
import 'streams_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firebaseService = FirebaseService();
  String? _favoriteAirport;
  bool _notificationsEnabled = true;
  String _language = 'pl';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final preferences = await _firebaseService.getUserPreferences();
      if (preferences != null) {
        setState(() {
          _favoriteAirport = preferences['favoriteAirport'];
          _notificationsEnabled = preferences['notificationsEnabled'] ?? true;
          _language = preferences['language'] ?? 'pl';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd ładowania ustawień: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    // Przygotowanie na przyszłość - zapisywanie preferencji
    // Obecnie funkcje są wyłączone, ale kod jest przygotowany do użycia
    try {
      await _firebaseService.saveUserPreferences(
        favoriteAirport: _favoriteAirport,
        notificationsEnabled: _notificationsEnabled,
        language: _language,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ustawienia zostały zapisane')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd zapisywania ustawień: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _firebaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd wylogowania: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _firebaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Zapisz ustawienia',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informacje o koncie',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (user != null) ...[
                    Text('Email: ${user.email}'),
                    Text('UID: ${user.uid}'),
                    if (user.emailVerified)
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('Email zweryfikowany'),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 16),
                          SizedBox(width: 4),
                          Text('Email niezweryfikowany'),
                        ],
                      ),
                  ] else
                    const Text('Nie jesteś zalogowany'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preferencje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  //  Przygotowanie na przyszłość - ulubione lotnisko
                  // Może być używane do automatycznego wyboru lotniska przy starcie aplikacji
                  // lub wyświetlania jako domyślne w mapie
                  // DropdownButtonFormField<String>(
                  //   value: _favoriteAirport,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Ulubione lotnisko',
                  //     border: OutlineInputBorder(),
                  //   ),
                  //   items: airports.map((airport) {
                  //     return DropdownMenuItem(
                  //       value: airport.icao,
                  //       child: Text('${airport.icao} - ${airport.name}'),
                  //     );
                  //   }).toList(),
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _favoriteAirport = value;
                  //     });
                  //   },
                  // ),
                  // const SizedBox(height: 16),

                  // Przygotowanie na przyszłość - powiadomienia
                  // Wymaga implementacji Firebase Cloud Messaging i logiki powiadomień
                  // SwitchListTile(
                  //   title: const Text('Powiadomienia'),
                  //   subtitle: const Text('Otrzymuj powiadomienia o lotach'),
                  //   value: _notificationsEnabled,
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _notificationsEnabled = value;
                  //     });
                  //   },
                  // ),

                  // Przygotowanie na przyszłość - zmiana języka
                  // Wymaga implementacji lokalizacji (flutter_localizations, intl)
                  // i tłumaczeń dla wszystkich tekstów w aplikacji
                  // DropdownButtonFormField<String>(
                  //   value: _language,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Język',
                  //     border: OutlineInputBorder(),
                  //   ),
                  //   items: const [
                  //     DropdownMenuItem(value: 'pl', child: Text('Polski')),
                  //     DropdownMenuItem(value: 'en', child: Text('English')),
                  //   ],
                  //   onChanged: (value) {
                  //     setState(() {
                  //       _language = value!;
                  //     });
                  //   },
                  // ),

                  // Informacja o przyszłych funkcjach
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Funkcje takie jak ulubione lotnisko, powiadomienia i zmiana języka są przygotowane w kodzie i będą dostępne w przyszłych wersjach aplikacji.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Akcje',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (user != null) ...[
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('Wyloguj się'),
                      onTap: _signOut,
                    ),
                    const Divider(),
                  ] else ...[
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: const Text('Zaloguj się'),
                      onTap: () {
                        Navigator.of(context).pushNamed('/auth');
                      },
                    ),
                    const Divider(),
                  ],

                  ListTile(
                    leading: const Icon(Icons.radio),
                    title: const Text('Moje streamy'),
                    subtitle: const Text('Zarządzaj prywatnymi streamami'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const StreamsManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('O aplikacji'),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('TowerFlower'),
                          content: const Text(
                            'Aplikacja do śledzenia lotów i informacji lotniskowych.\n\n'
                            'Wersja: 1.0.0\n'
                            'Zintegrowana z Firebase\n'
                            'Prywatne streamy użytkowników',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Zamknij'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
