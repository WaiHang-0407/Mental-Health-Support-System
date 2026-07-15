import 'package:flutter/material.dart';

import '../models/activity_path.dart';
import '../repositories/activity_path_repository.dart';

class ActivityPathController extends ChangeNotifier {
  final ActivityPathRepository _repo;

  ActivityPathController({ActivityPathRepository? repo})
    : _repo = repo ?? ActivityPathRepository();

  List<ActivityPath> paths = [];
  bool isLoading = false;
  String? errorMessage;

  List<ActivityPath> get selectedPaths =>
      paths.where((path) => path.isSelected).toList();

  List<ActivityPath> get savedPaths =>
      paths.where((path) => path.isSaved).toList();

  Future<void> loadPaths() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      paths = await _repo.getActivePaths();
    } catch (_) {
      errorMessage = 'Unable to load activity paths.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectPath(ActivityPath path) async {
    await _repo.selectPath(path.id);
    _replacePath(path.copyWith(isSelected: true, lastOpenedAt: DateTime.now()));
  }

  Future<void> updateProgress({
    required ActivityPath path,
    required int currentPageNumber,
    required int completedPageCount,
    required bool isCompleted,
  }) async {
    await _repo.updateProgress(
      activityPathId: path.id,
      currentPageNumber: currentPageNumber,
      completedPageCount: completedPageCount,
      isCompleted: isCompleted,
    );

    _replacePath(
      path.copyWith(
        isSelected: true,
        currentPageNumber: currentPageNumber,
        completedPageCount: completedPageCount,
        lastOpenedAt: DateTime.now(),
        completedAt: isCompleted ? DateTime.now() : null,
      ),
    );
  }

  Future<void> setSaved(ActivityPath path, bool isSaved) async {
    await _repo.setSaved(activityPathId: path.id, isSaved: isSaved);
    _replacePath(
      path.copyWith(
        isSaved: isSaved,
        savedAt: isSaved ? DateTime.now() : null,
      ),
    );
  }

  void _replacePath(ActivityPath updatedPath) {
    final index = paths.indexWhere((path) => path.id == updatedPath.id);
    if (index == -1) return;

    paths[index] = updatedPath;
    notifyListeners();
  }
}
