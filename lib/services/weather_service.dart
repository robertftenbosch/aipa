import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  static const _weatherDescriptions = {
    0: 'helder',
    1: 'overwegend helder',
    2: 'gedeeltelijk bewolkt',
    3: 'bewolkt',
    45: 'mist',
    48: 'rijpmist',
    51: 'lichte motregen',
    53: 'motregen',
    55: 'dichte motregen',
    61: 'lichte regen',
    63: 'regen',
    65: 'zware regen',
    71: 'lichte sneeuw',
    73: 'sneeuw',
    75: 'zware sneeuw',
    80: 'lichte regenbuien',
    81: 'regenbuien',
    82: 'zware regenbuien',
    95: 'onweer',
    96: 'onweer met hagel',
    99: 'zwaar onweer met hagel',
  };

  /// Get current weather for a location. Defaults to Amsterdam.
  Future<String> getCurrentWeather({
    double latitude = 52.37,
    double longitude = 4.89,
    String city = 'Amsterdam',
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m',
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return 'Kon het weer niet ophalen.';
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;

      final temp = current['temperature_2m'];
      final code = current['weather_code'] as int;
      final wind = current['wind_speed_10m'];
      final humidity = current['relative_humidity_2m'];

      final description = _weatherDescriptions[code] ?? 'onbekend';

      return 'Het weer in $city: $description, '
          '$temp°C, wind $wind km/u, luchtvochtigheid $humidity%.';
    } catch (_) {
      return 'Kon het weer niet ophalen. Controleer de internetverbinding.';
    }
  }
}
