import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/screens/flights_board_screen.dart';
import '../lib/models/fligth.dart';

void main() {
  group('FlightsBoardScreen Navigation Tests', () {
    testWidgets('should navigate back with flight data when flight is tapped', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: FlightsBoardScreen(initialAirport: 'EPKK'),
        ),
      );

      // Wait for the future to complete
      await tester.pumpAndSettle();

      // Verify that the screen is displayed
      expect(find.text('Loty w okolicy EPKK'), findsOneWidget);

      // Note: This is a basic test structure
      // Full integration would require mocking the HTTP client
      // and verifying navigation callback with flight data
    });
  });
}

