import 'package:flutter/foundation.dart';

import '../models/activity_path.dart';
import '../services/admin_activity_logs_service.dart';
import '../services/activity_paths_service.dart';

enum ActivityPathStatusFilter {
  active,
  archived,
  deleted,
}

class ActivityPathsController extends ChangeNotifier {
  ActivityPathsController({
    ActivityPathsService? activityPathsService,
    AdminActivityLogsService? adminActivityLogsService,
  })  : _activityPathsService = activityPathsService ?? ActivityPathsService(),
        _adminActivityLogsService =
            adminActivityLogsService ?? AdminActivityLogsService();

  final ActivityPathsService _activityPathsService;
  final AdminActivityLogsService _adminActivityLogsService;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedPathId;
  List<ActivityPath> _activityPaths = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get selectedPathId => _selectedPathId;
  List<ActivityPath> get activityPaths => _activityPaths;

  ActivityPath? get selectedPath {
    final pathId = _selectedPathId;
    if (pathId == null) {
      return null;
    }

    for (final path in _activityPaths) {
      if (path.id == pathId) {
        return path;
      }
    }
    return null;
  }

  List<ActivityPath> pathsFor(ActivityPathStatusFilter filter) {
    return _activityPaths.where((path) {
      return switch (filter) {
        ActivityPathStatusFilter.active => !path.isDeleted && !path.isArchived,
        ActivityPathStatusFilter.archived => path.isArchived && !path.isDeleted,
        ActivityPathStatusFilter.deleted => path.isDeleted,
      };
    }).toList();
  }

  int countFor(ActivityPathStatusFilter filter) {
    return pathsFor(filter).length;
  }

  Future<void> loadActivityPaths() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activityPaths = await _activityPathsService.fetchActivityPaths();
      if (_selectedPathId == null && _activityPaths.isNotEmpty) {
        final activePaths = pathsFor(ActivityPathStatusFilter.active);
        _selectedPathId =
            activePaths.isNotEmpty ? activePaths.first.id : _activityPaths.first.id;
      }
    } catch (_) {
      _errorMessage = 'Unable to load activity paths.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectPath(String pathId) {
    _selectedPathId = pathId;
    notifyListeners();
  }

  void clearSelection() {
    _selectedPathId = null;
    notifyListeners();
  }

  Future<bool> createActivityPath(ActivityPathDraft input) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _activityPathsService.createActivityPath(input);
      await _adminActivityLogsService.log(
        action: 'activity_path_created',
        targetType: 'activity_path',
      );
      await loadActivityPaths();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (error) {
      _errorMessage = 'Unable to create activity path: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivityPath({
    required String activityPathId,
    required ActivityPathDraft input,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _activityPathsService.updateActivityPath(
        activityPathId: activityPathId,
        input: input,
      );
      await _adminActivityLogsService.log(
        action: 'activity_path_updated',
        targetType: 'activity_path',
        targetId: activityPathId,
      );
      await loadActivityPaths();
      _selectedPathId = activityPathId;
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (error) {
      _errorMessage = 'Unable to update activity path: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> archiveActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.archiveActivityPath(activityPathId),
      action: 'activity_path_archived',
      targetType: 'activity_path',
      targetId: activityPathId,
    );
  }

  Future<void> unarchiveActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.unarchiveActivityPath(activityPathId),
      action: 'activity_path_unarchived',
      targetType: 'activity_path',
      targetId: activityPathId,
    );
  }

  Future<void> deleteActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.deleteActivityPath(activityPathId),
      action: 'activity_path_deleted',
      targetType: 'activity_path',
      targetId: activityPathId,
    );
  }

  Future<void> _runMutation(
    Future<void> Function() mutation, {
    required String action,
    required String targetType,
    required String targetId,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await mutation();
      await _adminActivityLogsService.log(
        action: action,
        targetType: targetType,
        targetId: targetId,
      );
      await loadActivityPaths();
    } catch (_) {
      _errorMessage = 'Unable to update the selected activity path.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
