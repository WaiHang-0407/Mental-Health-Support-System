import 'package:flutter/material.dart';

import '../models/daily_activity.dart';
import '../services/admin_activity_logs_service.dart';
import '../services/daily_activities_service.dart';

class DailyActivitiesController extends ChangeNotifier {
  DailyActivitiesController({
    DailyActivitiesService? dailyActivitiesService,
    AdminActivityLogsService? adminActivityLogsService,
  })
      : _dailyActivitiesService =
            dailyActivitiesService ?? DailyActivitiesService(),
        _adminActivityLogsService =
            adminActivityLogsService ?? AdminActivityLogsService();

  final DailyActivitiesService _dailyActivitiesService;
  final AdminActivityLogsService _adminActivityLogsService;

  List<DailyActivity> _dailyActivities = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  List<DailyActivity> get dailyActivities => _dailyActivities;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> loadDailyActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dailyActivities =
          await _dailyActivitiesService.fetchDailyActivities();
    } catch (_) {
      _errorMessage = 'Unable to load daily activities.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDailyActivity(DailyActivity activity) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dailyActivitiesService.createDailyActivity(activity);
      await _adminActivityLogsService.log(
        action: 'daily_activity_created',
        targetType: 'daily_activity',
      );
      await loadDailyActivities();
      return true;
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Invalid daily activity.';
      return false;
    } catch (_) {
      _errorMessage = 'Unable to add daily activity.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateDailyActivity(DailyActivity activity) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dailyActivitiesService.updateDailyActivity(activity);
      await _adminActivityLogsService.log(
        action: 'daily_activity_updated',
        targetType: 'daily_activity',
        targetId: activity.id,
      );
      await loadDailyActivities();
      return true;
    } on ArgumentError catch (e) {
      _errorMessage = e.message?.toString() ?? 'Invalid daily activity.';
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update daily activity.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setActive(DailyActivity activity, bool isActive) async {
    final activityId = activity.id;
    if (activityId == null) return;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _dailyActivitiesService.setActive(
        activityId: activityId,
        isActive: isActive,
      );
      await _adminActivityLogsService.log(
        action: isActive
            ? 'daily_activity_restored'
            : 'daily_activity_deactivated',
        targetType: 'daily_activity',
        targetId: activityId,
      );
      await loadDailyActivities();
    } catch (_) {
      _errorMessage = isActive
          ? 'Unable to restore daily activity.'
          : 'Unable to deactivate daily activity.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
