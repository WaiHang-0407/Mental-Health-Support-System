import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/affirmation.dart';
import '../models/user_location.dart';
import '../models/weather_snapshot.dart';
import '../repositories/affirmations_table_repository.dart';
import 'affirmation_cache_service.dart';
import 'gemini_service.dart';
import 'user_location_service.dart';
import 'weather_service.dart';

class SelectedAffirmation {
  final Affirmation affirmation;
  final UserLocation? location;
  final WeatherSnapshot? weather;

  const SelectedAffirmation({
    required this.affirmation,
    this.location,
    this.weather,
  });
}

class AffirmationSelectionService {
  static const _cacheMaxAge = Duration(hours: 3);

  final AffirmationsTableRepository _affirmationsTable;
  final UserLocationService _locationService;
  final WeatherService _weatherService;
  final GeminiService _geminiService;
  final AffirmationCacheService _cacheService;

  AffirmationSelectionService({
    AffirmationsTableRepository? affirmationsTable,
    UserLocationService? locationService,
    WeatherService? weatherService,
    GeminiService? geminiService,
    AffirmationCacheService? cacheService,
  }) : _affirmationsTable =
           affirmationsTable ?? AffirmationsTableRepository(),
       _locationService = locationService ?? UserLocationService(),
       _weatherService = weatherService ?? WeatherService(),
       _geminiService = geminiService ?? GeminiService(),
       _cacheService = cacheService ?? AffirmationCacheService();

  Future<SelectedAffirmation?> chooseForCurrentLogin() async {
    final affirmations = await _affirmationsTable.fetchActiveAffirmations();
    if (affirmations.isEmpty) return null;

    final location = await _safeLocation();
    final weather = location == null ? null : await _safeWeather(location);
    final now = DateTime.now();
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final date = _dateKey(now);
    final weatherCategory = weather?.category ?? 'no-weather';

    final cachedChoice = await _readValidCachedChoice(
      affirmations: affirmations,
      userId: userId,
      date: date,
      weatherCategory: weatherCategory,
      now: now,
    );

    if (cachedChoice != null) {
      return SelectedAffirmation(
        affirmation: cachedChoice,
        location: location,
        weather: weather,
      );
    }

    final geminiChoiceId = await _geminiService.chooseAffirmation(
      affirmations: affirmations,
      location: location,
      weather: weather,
    );
    final geminiChoice = _findById(affirmations, geminiChoiceId);

    if (geminiChoice != null) {
      await _saveChoice(
        affirmation: geminiChoice,
        userId: userId,
        date: date,
        weatherCategory: weatherCategory,
        selectedAt: now,
      );

      return SelectedAffirmation(
        affirmation: geminiChoice,
        location: location,
        weather: weather,
      );
    }

    final sortedAffirmations = [...affirmations]
      ..sort((a, b) => a.id.compareTo(b.id));
    final seed = _selectionSeed(location, weather);
    final index = _positiveHash(seed) % sortedAffirmations.length;
    final fallbackChoice = sortedAffirmations[index];

    await _saveChoice(
      affirmation: fallbackChoice,
      userId: userId,
      date: date,
      weatherCategory: weatherCategory,
      selectedAt: now,
    );

    return SelectedAffirmation(
      affirmation: fallbackChoice,
      location: location,
      weather: weather,
    );
  }

  Future<UserLocation?> _safeLocation() async {
    try {
      return await _locationService.getCurrentLocation();
    } catch (_) {
      return null;
    }
  }

  Future<WeatherSnapshot?> _safeWeather(UserLocation location) async {
    try {
      return await _weatherService.fetchCurrentWeather(location);
    } catch (_) {
      return null;
    }
  }

  Future<Affirmation?> _readValidCachedChoice({
    required List<Affirmation> affirmations,
    required String userId,
    required String date,
    required String weatherCategory,
    required DateTime now,
  }) async {
    final cached = await _cacheService.read();
    if (cached == null) return null;
    if (cached.userId != userId) return null;
    if (cached.date != date) return null;
    if (cached.weatherCategory != weatherCategory) return null;
    if (now.difference(cached.selectedAt) > _cacheMaxAge) return null;

    return _findById(affirmations, cached.affirmationId);
  }

  Future<void> _saveChoice({
    required Affirmation affirmation,
    required String userId,
    required String date,
    required String weatherCategory,
    required DateTime selectedAt,
  }) async {
    await _cacheService.save(
      affirmationId: affirmation.id,
      userId: userId,
      date: date,
      weatherCategory: weatherCategory,
      selectedAt: selectedAt,
    );
  }

  Affirmation? _findById(List<Affirmation> affirmations, String? id) {
    if (id == null) return null;

    for (final affirmation in affirmations) {
      if (affirmation.id == id) return affirmation;
    }

    return null;
  }

  String _selectionSeed(UserLocation? location, WeatherSnapshot? weather) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final date = _dateKey(DateTime.now());
    final latitude = location?.latitude.toStringAsFixed(1) ?? 'no-lat';
    final longitude = location?.longitude.toStringAsFixed(1) ?? 'no-lon';
    final weatherCategory = weather?.category ?? 'no-weather';
    final weatherCode = weather?.weatherCode.toString() ?? 'no-code';

    return '$userId|$date|$latitude|$longitude|$weatherCategory|$weatherCode';
  }

  String _dateKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  int _positiveHash(String value) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }
}
