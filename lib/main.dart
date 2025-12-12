import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
//import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/map_screen.dart';
import 'screens/flights_board_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/streams_management_screen.dart';
//import 'screens/aircraft_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Firebase Crashlytics (tylko dla platform natywnych, nie web)
    if (!kIsWeb) {
      try {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        
        // Pass all uncaught asynchronous errors to Crashlytics
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      } catch (e) {
        debugPrint('Błąd inicjalizacji Crashlytics: $e');
        // Fallback error handling
        FlutterError.onError = (errorDetails) {
          FlutterError.presentError(errorDetails);
        };
        
        PlatformDispatcher.instance.onError = (error, stack) {
          debugPrint('Uncaught error: $error\nStack: $stack');
          return true;
        };
      }
    } else {
      // Na web tylko loguj błędy do konsoli
      FlutterError.onError = (errorDetails) {
        FlutterError.presentError(errorDetails);
      };
      
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Uncaught error: $error\nStack: $stack');
        return true;
      };
    }
  } catch (e, stackTrace) {
    debugPrint('Błąd inicjalizacji Firebase: $e');
    debugPrint('Stack trace: $stackTrace');
    // Kontynuuj uruchomienie aplikacji nawet jeśli Firebase się nie zainicjalizował
    // Aplikacja może działać w trybie offline
    FlutterError.onError = (errorDetails) {
      FlutterError.presentError(errorDetails);
    };
    
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Uncaught error: $error\nStack: $stack');
      return true;
    };
  }
  
  runApp(TowerFlowerApp());
}

class TowerFlowerApp extends StatelessWidget {
  const TowerFlowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowerFlower',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      navigatorObservers: [
        // FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      initialRoute: '/',
      routes: {
        '/': (context) {
          return SplashScreen();
        },
        '/auth': (context) => AuthScreen(),
        '/map': (context) => MapScreen(),
        '/settings': (context) => SettingsScreen(),
        '/streams': (context) => StreamsManagementScreen(),
        '/flights': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as String?;
          return FlightsBoardScreen(initialAirport: args ?? 'EPKK');
        },
      },
    );
  }
}
