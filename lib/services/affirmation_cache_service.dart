import 'package:shared_preferences/shared_preferences.dart';

class CachedAffirmationChoice {
  final String affirmationId;
  final String userId;
  final String date;
  final String weatherCategory;
  final DateTime selectedAt;

  const CachedAffirmationChoice({
    required this.affirmationId,
    required this.userId,
    required this.date,
    required this.weatherCategory,
    required this.selectedAt,
  });
}

class AffirmationCacheService {
  static const _affirmationIdKey = 'affirmation_cache_id';
  static const _userIdKey = 'affirmation_cache_user_id';
  static const _dateKey = 'affirmation_cache_date';
  static const _weatherCategoryKey = 'affirmation_cache_weather_category';
  static const _selectedAtKey = 'affirmation_cache_selected_at';

  Future<CachedAffirmationChoice?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final affirmationId = preferences.getString(_affirmationIdKey);
    final userId = preferences.getString(_userIdKey);
    final date = preferences.getString(_dateKey);
    final weatherCategory = preferences.getString(_weatherCategoryKey);
    final selectedAtText = preferences.getString(_selectedAtKey);

    if (affirmationId == null ||
        userId == null ||
        date == null ||
        weatherCategory == null ||
        selectedAtText == null) {
      return null;
    }

    final selectedAt = DateTime.tryParse(selectedAtText);
    if (selectedAt == null) return null;

    return CachedAffirmationChoice(
      affirmationId: affirmationId,
      userId: userId,
      date: date,
      weatherCategory: weatherCategory,
      selectedAt: selectedAt,
    );
  }

  Future<void> save({
    required String affirmationId,
    required String userId,
    required String date,
    required String weatherCategory,
    required DateTime selectedAt,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_affirmationIdKey, affirmationId);
    await preferences.setString(_userIdKey, userId);
    await preferences.setString(_dateKey, date);
    await preferences.setString(_weatherCategoryKey, weatherCategory);
    await preferences.setString(_selectedAtKey, selectedAt.toIso8601String());
  }
}
