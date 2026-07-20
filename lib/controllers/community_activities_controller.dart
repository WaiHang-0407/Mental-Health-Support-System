import 'package:flutter/foundation.dart';

import '../models/community_activity.dart';
import '../services/admin_activity_logs_service.dart';
import '../services/community_activities_service.dart';

enum ActivityStatusFilter {
  open,
  registrationClosed,
  completed,
  archived,
  cancelled,
}

class CommunityActivitiesController extends ChangeNotifier {
  CommunityActivitiesController({
    CommunityActivitiesService? communityActivitiesService,
    AdminActivityLogsService? adminActivityLogsService,
  })  : _communityActivitiesService =
            communityActivitiesService ?? CommunityActivitiesService(),
        _adminActivityLogsService =
            adminActivityLogsService ?? AdminActivityLogsService();

  final CommunityActivitiesService _communityActivitiesService;
  final AdminActivityLogsService _adminActivityLogsService;

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
        ActivityStatusFilter.open =>
          !activity.isDeleted &&
              !activity.isArchived &&
              !activity.isRegistrationClosed &&
              !activity.isCompleted,
        ActivityStatusFilter.registrationClosed =>
          !activity.isDeleted &&
              !activity.isArchived &&
              activity.hasLockedRegistration,
        ActivityStatusFilter.completed =>
          !activity.isDeleted && !activity.isArchived && activity.isCompleted,
        ActivityStatusFilter.archived =>
          activity.isArchived && !activity.isDeleted,
        ActivityStatusFilter.cancelled => activity.isDeleted,
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
              !sponsorship.isDeleted && !sponsorship.isArchived,
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
      final openActivities = activitiesFor(ActivityStatusFilter.open);
      if (openActivities.isNotEmpty && _selectedActivityId == null) {
        _selectedActivityId = openActivities.first.id;
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
      await _adminActivityLogsService.log(
        action: 'community_activity_created',
        targetType: 'community_activity',
      );
      await loadActivities();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (error) {
      _errorMessage = 'Unable to create community activity: $error';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateActivity({
    required String activityId,
    required CreateCommunityActivityInput input,
    bool enforceScheduleRules = true,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final existingActivity = _activities.cast<CommunityActivity?>().firstWhere(
            (activity) => activity?.id == activityId,
            orElse: () => null,
          );
      await _communityActivitiesService.updateActivity(
        activityId: activityId,
        input: input,
        enforceScheduleRules:
            enforceScheduleRules && existingActivity?.hasLockedRegistration != true,
      );
      await _adminActivityLogsService.log(
        action: 'community_activity_updated',
        targetType: 'community_activity',
        targetId: activityId,
      );
      await loadActivities();
      _selectedActivityId = activityId;
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (error) {
      _errorMessage = 'Unable to update community activity: $error';
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
      await _adminActivityLogsService.log(
        action: 'sponsorship_created',
        targetType: 'sponsorship',
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

  Future<bool> updateSponsorship({
    required String sponsorshipId,
    required SponsorshipDraft sponsorship,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _communityActivitiesService.updateSponsorship(
        sponsorshipId: sponsorshipId,
        sponsorship: sponsorship,
      );
      await _adminActivityLogsService.log(
        action: 'sponsorship_updated',
        targetType: 'sponsorship',
        targetId: sponsorshipId,
      );
      await loadActivities();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update sponsorship.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> archiveActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveActivity(activityId),
      action: 'community_activity_archived',
      targetType: 'community_activity',
      targetId: activityId,
    );
  }

  Future<void> unarchiveActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.unarchiveActivity(activityId),
      action: 'community_activity_unarchived',
      targetType: 'community_activity',
      targetId: activityId,
    );
  }

  Future<void> deleteActivity(String activityId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteActivity(activityId),
      action: 'community_activity_deleted',
      targetType: 'community_activity',
      targetId: activityId,
    );
  }

  Future<void> archiveSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveSponsorship(sponsorshipId),
      action: 'sponsorship_archived',
      targetType: 'sponsorship',
      targetId: sponsorshipId,
    );
  }

  Future<void> unarchiveSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.unarchiveSponsorship(sponsorshipId),
      action: 'sponsorship_unarchived',
      targetType: 'sponsorship',
      targetId: sponsorshipId,
    );
  }

  Future<void> deleteSponsorship(String sponsorshipId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteSponsorship(sponsorshipId),
      action: 'sponsorship_deleted',
      targetType: 'sponsorship',
      targetId: sponsorshipId,
    );
  }

  Future<void> archiveProduct(String productId) async {
    await _runMutation(
      () => _communityActivitiesService.archiveProduct(productId),
      action: 'sponsorship_product_archived',
      targetType: 'sponsorship_product',
      targetId: productId,
    );
  }

  Future<void> unarchiveProduct(String productId) async {
    await _runMutation(
      () => _communityActivitiesService.unarchiveProduct(productId),
      action: 'sponsorship_product_unarchived',
      targetType: 'sponsorship_product',
      targetId: productId,
    );
  }

  Future<void> deleteProduct(String productId) async {
    await _runMutation(
      () => _communityActivitiesService.deleteProduct(productId),
      action: 'sponsorship_product_deleted',
      targetType: 'sponsorship_product',
      targetId: productId,
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
      await _adminActivityLogsService.log(
        action: 'sponsorship_product_updated',
        targetType: 'sponsorship_product',
        targetId: productId,
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
      await loadActivities();
    } catch (_) {
      _errorMessage = 'Unable to update the selected record.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
