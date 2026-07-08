import 'package:flutter/foundation.dart';

import '../models/activity_path.dart';
import '../services/activity_paths_service.dart';

enum ActivityPathStatusFilter {
  active,
  archived,
  deleted,
}

class ActivityPathsController extends ChangeNotifier {
  ActivityPathsController({ActivityPathsService? activityPathsService})
      : _activityPathsService = activityPathsService ?? ActivityPathsService();

  final ActivityPathsService _activityPathsService;

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
      await loadActivityPaths();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create activity path.';
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
      await loadActivityPaths();
      _selectedPathId = activityPathId;
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update activity path.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> archiveActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.archiveActivityPath(activityPathId),
    );
  }

  Future<void> unarchiveActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.unarchiveActivityPath(activityPathId),
    );
  }

  Future<void> deleteActivityPath(String activityPathId) {
    return _runMutation(
      () => _activityPathsService.deleteActivityPath(activityPathId),
    );
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadActivityPaths();
    } catch (_) {
      _errorMessage = 'Unable to update the selected activity path.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
