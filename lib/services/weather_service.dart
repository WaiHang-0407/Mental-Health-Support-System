import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_location.dart';
import '../models/weather_snapshot.dart';

class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherSnapshot?> fetchCurrentWeather(UserLocation location) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'current': 'weather_code,temperature_2m',
    });

    final response = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>?;
    if (current == null) return null;

    final weatherCode = current['weather_code'];
    if (weatherCode is! num) return null;

    final temperature = current['temperature_2m'];

    return WeatherSnapshot(
      weatherCode: weatherCode.toInt(),
      temperature: temperature is num ? temperature.toDouble() : null,
      category: _categoryForWeatherCode(weatherCode.toInt()),
    );
  }

  String _categoryForWeatherCode(int code) {
    if (code == 0) return 'clear';
    if (code == 1 || code == 2 || code == 3) return 'cloudy';
    if (code == 45 || code == 48) return 'foggy';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return 'rainy';
    }
    if (code >= 71 && code <= 77) return 'snowy';
    if (code >= 95 && code <= 99) return 'stormy';
    return 'unknown';
  }
}
