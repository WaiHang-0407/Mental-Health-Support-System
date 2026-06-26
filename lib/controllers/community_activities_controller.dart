import 'package:flutter/foundation.dart';

import '../models/community_activity.dart';
import '../services/community_activities_service.dart';

enum ActivityStatusFilter {
  active,
  archived,
  deleted,
}

class CommunityActivitiesController extends ChangeNotifier {
  CommunityActivitiesController({
    CommunityActivitiesService? communityActivitiesService,
  }) : _communityActivitiesService =
            communityActivitiesService ?? CommunityActivitiesService();

  final CommunityActivitiesService _communityActivitiesService;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _selectedActivityId;
  List<CommunityActivity> _activities = const [];
  List<ActivitySponsorship> _sponsorships = const [];
  List<ActivityParticipant> _participants = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<CommunityActivity> get activities => _activities;
  List<ActivitySponsorship> get sponsorships => _sponsorships;
  List<ActivityParticipant> get participants => _participants;
  String? get selectedActivityId => _selectedActivityId;
  DateTime get minimumEventDate => _communityActivitiesService.minimumEventDate();

  List<CommunityActivity> activitiesFor(ActivityStatusFilter filter) {
    return _activities.where((activity) {
      return switch (filter) {
        ActivityStatusFilter.active =>
          !activity.isDeleted && !activity.isArchived,
        ActivityStatusFilter.archived =>
          activity.isArchived && !activity.isDeleted,
        ActivityStatusFilter.deleted => activity.isDeleted,
      };
    }).toList();
  }

  int countFor(ActivityStatusFilter filter) {
    return activitiesFor(filter).length;
  }

  List<ActivitySponsorship> get availableSponsorships {
    return _sponsorships
        .where(
          (sponsorship) =>
              sponsorship.activityId == null &&
              !sponsorship.isDeleted &&
              !sponsorship.isArchived,
        )
        .toList();
  }

  CommunityActivity? get selectedActivity {
    final activityId = _selectedActivityId;
    if (activityId == null) {
      return null;
    }

    for (final activity in _activities) {
      if (activity.id == activityId) {
        return activity;
      }
    }

    return null;
  }

  DateTime registrationDeadlineFor(DateTime eventDate) {
    return _communityActivitiesService.registrationDeadlineFor(eventDate);
  }

  Future<void> loadActivities() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activities = await _communityActivitiesService.fetchActivities();
      _sponsorships = await _communityActivitiesService.fetchSponsorships();
      final activeActivities = activitiesFor(ActivityStatusFilter.active);
      if (activeActivities.isNotEmpty && _selectedActivityId == null) {
        _selectedActivityId = activeActivities.first.id;
        _participants = await _communityActivitiesService.fetchParticipants(
          _selectedActivityId!,
        );
      }
    } catch (_) {
      _errorMessage = 'Unable to load community activities.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectActivity(String activityId) async {
    _selectedActivityId = activityId;
    _participants = const [];
    notifyListeners();

    try {
      _participants = await _communityActivitiesService.fetchParticipants(
        activityId,
      );
    } catch (_) {
      _errorMessage = 'Unable to load participants.';
    } finally {
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedActivityId = null;
    _participants = const [];
    notifyListeners();
  }

  Future<bool> createActivity(CreateCommunityActivityInput input) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityActivitiesService.createActivity(input);
      await loadActivities();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create community activity.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivity({
    required String activityId,
    required CreateCommunityActivityInput input,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityActivitiesService.updateActivity(
        activityId: activityId,
        input: input,
      );
      await loadActivities();
      _selectedActivityId = activityId;
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update community activity.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> createSponsorship({
    required SponsorshipDraft sponsorship,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityActivitiesService.createSponsorship(
        sponsorship: sponsorship,
      );
      await loadActivities();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to add sponsorship.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> archiveActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveActivity(activityId),
    );
  }

  Future<void> unarchiveActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.unarchiveActivity(activityId),
    );
  }

  Future<void> deleteActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteActivity(activityId),
    );
  }

  Future<void> archiveSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveSponsorship(sponsorshipId),
    );
  }

  Future<void> unarchiveSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.unarchiveSponsorship(sponsorshipId),
    );
  }

  Future<void> deleteSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteSponsorship(sponsorshipId),
    );
  }

  Future<void> archiveProduct(String productId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveProduct(productId),
    );
  }

  Future<void> deleteProduct(String productId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteProduct(productId),
    );
  }

  Future<bool> updateProduct({
    required String productId,
    required String sponsorshipId,
    required UpdateSponsorshipProductInput input,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityActivitiesService.updateProduct(
        productId: productId,
        sponsorshipId: sponsorshipId,
        input: input,
      );
      await loadActivities();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update product.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      await loadActivities();
    } catch (_) {
      _errorMessage = 'Unable to update the selected record.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
