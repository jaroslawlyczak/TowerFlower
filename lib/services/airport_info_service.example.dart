// Przykładowy plik pokazujący jak używać AirportInfoService z kluczem API
// 
// W rzeczywistej aplikacji ustaw klucz API przez:
// 1. Zmienną środowiskową (.env)
// 2. Metodę setApiKey() po utworzeniu instancji
// 3. Konstruktor AirportInfoService(apiKey: 'TWÓJ_KLUCZ')

import 'airport_info_service.dart';

void exampleUsage() {
  // Przykład 1: Ustawienie klucza przez konstruktor
  // final service1 = AirportInfoService(apiKey: 'TWÓJ_KLUCZ_API');
  
  // Przykład 2: Ustawienie klucza po utworzeniu
  final service2 = AirportInfoService();
  service2.setApiKey('TWÓJ_KLUCZ_API');
  
  // Przykład 3: Użycie zmiennej środowiskowej (wymaga flutter_dotenv)
  // final apiKey = dotenv.env['AVIATIONSTACK_API_KEY'] ?? '';
  // final service3 = AirportInfoService(apiKey: apiKey);
  
  // Użyj service2 do wywołania metod API
  // service2.fetchArrivals('EPKK');
}

