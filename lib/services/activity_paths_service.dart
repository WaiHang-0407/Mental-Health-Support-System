import '../models/activity_path.dart';
import '../repositories/activity_paths_repository.dart';

class ActivityPathsService {
  ActivityPathsService({ActivityPathsRepository? activityPathsRepository})
      : _activityPathsRepository =
            activityPathsRepository ?? ActivityPathsRepository();

  final ActivityPathsRepository _activityPathsRepository;

  Future<List<ActivityPath>> fetchActivityPaths() {
    return _activityPathsRepository.fetchActivityPaths();
  }

  Future<void> createActivityPath(ActivityPathDraft input) {
    _validateDraft(input);
    return _activityPathsRepository.createActivityPath(_trimmedDraft(input));
  }

  Future<void> updateActivityPath({
    required String activityPathId,
    required ActivityPathDraft input,
  }) {
    _validateDraft(input);
    return _activityPathsRepository.updateActivityPath(
      activityPathId: activityPathId,
      input: _trimmedDraft(input),
    );
  }

  Future<void> archiveActivityPath(String activityPathId) {
    return _activityPathsRepository.archiveActivityPath(activityPathId);
  }

  Future<void> unarchiveActivityPath(String activityPathId) {
    return _activityPathsRepository.unarchiveActivityPath(activityPathId);
  }

  Future<void> deleteActivityPath(String activityPathId) {
    return _activityPathsRepository.deleteActivityPath(activityPathId);
  }

  void _validateDraft(ActivityPathDraft input) {
    if (input.title.trim().isEmpty) {
      throw ArgumentError('Enter the activity path title.');
    }
    if (input.pages.isEmpty) {
      throw ArgumentError('Add at least one page.');
    }

    for (var index = 0; index < input.pages.length; index += 1) {
      final page = input.pages[index];
      if (page.body.trim().isEmpty) {
        throw ArgumentError('Enter text for page ${index + 1}.');
      }
    }
  }

  ActivityPathDraft _trimmedDraft(ActivityPathDraft input) {
    return ActivityPathDraft(
      title: input.title.trim(),
      description: input.description.trim(),
      createdBy: input.createdBy,
      coverImageUrl: input.coverImageUrl,
      coverImageBytes: input.coverImageBytes,
      coverImageFileName: input.coverImageFileName,
      coverImageMimeType: input.coverImageMimeType,
      pages: [
        for (final page in input.pages)
          ActivityPathPageDraft(
            title: page.title.trim(),
            body: page.body.trim(),
            images: page.images,
          ),
      ],
    );
  }
}
