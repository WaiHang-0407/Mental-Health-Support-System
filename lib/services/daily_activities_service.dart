import '../models/daily_activity.dart';
import '../repositories/daily_activities_repository.dart';

class DailyActivitiesService {
  DailyActivitiesService({DailyActivitiesRepository? dailyActivitiesRepository})
      : _dailyActivitiesRepository =
            dailyActivitiesRepository ?? DailyActivitiesRepository();

  final DailyActivitiesRepository _dailyActivitiesRepository;

  Future<List<DailyActivity>> fetchDailyActivities() {
    return _dailyActivitiesRepository.fetchDailyActivities();
  }

  Future<void> createDailyActivity(DailyActivity activity) {
    _validate(activity);
    return _dailyActivitiesRepository.createDailyActivity(activity);
  }

  Future<void> updateDailyActivity(DailyActivity activity) {
    _validate(activity);
    return _dailyActivitiesRepository.updateDailyActivity(activity);
  }

  Future<void> setActive({
    required String activityId,
    required bool isActive,
  }) {
    return _dailyActivitiesRepository.setActive(
      activityId: activityId,
      isActive: isActive,
    );
  }

  void _validate(DailyActivity activity) {
    if (activity.title.trim().isEmpty) {
      throw ArgumentError('Enter a daily activity title.');
    }
    if (activity.description.trim().isEmpty) {
      throw ArgumentError('Enter daily activity details.');
    }
    final duration = activity.durationMinutes;
    if (duration != null && duration <= 0) {
      throw ArgumentError('Duration must be greater than 0.');
    }
  }
}
