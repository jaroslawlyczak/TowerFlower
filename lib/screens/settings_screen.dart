import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';
// import '../models/airports_data.dart'; // Przygotowanie na przyszłość - ulubione lotnisko
import 'streams_management_screen.dart';
import 'airports_management_screen.dart';
import 'my_photos_screen.dart';

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
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    try {
      String? apiKey;
      
      // Najpierw spróbuj wczytać z Firebase (jeśli użytkownik jest zalogowany)
      if (_firebaseService.currentUser != null) {
        apiKey = await _firebaseService.getApiKeyFromFirebase();
      }
      
      // Jeśli nie ma w Firebase, wczytaj lokalnie
      if (apiKey == null || apiKey.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        apiKey = prefs.getString('aviationstack_api_key') ?? '';
      }
      
      if (apiKey.isNotEmpty) {
        _apiKeyController.text = apiKey;
      }
    } catch (e) {
      debugPrint('Błąd ładowania klucza API: $e');
      // Fallback do lokalnego klucza
      try {
        final prefs = await SharedPreferences.getInstance();
        final apiKey = prefs.getString('aviationstack_api_key') ?? '';
        if (apiKey.isNotEmpty) {
          _apiKeyController.text = apiKey;
        }
      } catch (e2) {
        debugPrint('Błąd ładowania lokalnego klucza API: $e2');
      }
    }
  }

  Future<void> _saveApiKeyLocally() async {
    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wprowadź klucz API'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aviationstack_api_key', apiKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klucz API został zapisany lokalnie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisywania klucza API: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveApiKeyToFirebase() async {
    try {
      final apiKey = _apiKeyController.text.trim();
      if (apiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wprowadź klucz API'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (_firebaseService.currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Musisz być zalogowany, aby zapisać klucz w Firebase'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _firebaseService.saveApiKeyToFirebase(apiKey);
      
      // Zapisz również lokalnie jako backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('aviationstack_api_key', apiKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Klucz API został zapisany w Firebase i lokalnie'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd zapisywania klucza API w Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

          // API Key section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Klucz API Aviationstack',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Wymagany do wyświetlania przylotów i odlotów. Możesz uzyskać klucz na aviationstack.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible,
                    decoration: InputDecoration(
                      labelText: 'Klucz API',
                      hintText: 'Wprowadź klucz API',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _apiKeyVisible ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _apiKeyVisible = !_apiKeyVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saveApiKeyLocally,
                          icon: const Icon(Icons.phone_android),
                          label: const Text('Zapisz lokalnie'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveApiKeyToFirebase,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('Zapisz w Firebase'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_firebaseService.currentUser == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Zaloguj się, aby zapisać klucz w Firebase',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
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
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Moje zdjęcia'),
                    subtitle: const Text('Zobacz wszystkie swoje zdjęcia'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const MyPhotosScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.local_airport),
                    title: const Text('Zarządzanie lotniskami'),
                    subtitle: const Text('Dodaj lub usuń lotniska'),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AirportsManagementScreen(),
                        ),
                      );
                      // Po powrocie z zarządzania lotniskami, odśwież ekran ustawień
                      // (map_screen przeładuje lotniska po powrocie z ustawień)
                      if (mounted) {
                        setState(() {});
                      }
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
