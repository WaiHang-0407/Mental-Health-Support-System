// controllers/community_activity_controller.dart
import 'package:flutter/material.dart';
import '../models/community_activity.dart';
import '../repositories/community_activity_table_repository.dart';

class CommunityActivityController extends ChangeNotifier {
  final CommunityActivityRepository _repo = CommunityActivityRepository();
  List<CommunityActivity> activities = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadActivities() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      activities = await _repo.getActivities();
    } catch (e) {
      errorMessage = 'Unable to load community activities.';
      activities = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(CommunityActivity activity) async {
    await _repo.register(activity.id);
    _updateActivity(
      activity.id,
      isRegistered: true,
      registeredCount: activity.registeredCount + 1,
    );
  }

  Future<void> cancelRegistration(CommunityActivity activity) async {
    await _repo.cancelRegistration(activity.id);
    _updateActivity(
      activity.id,
      isRegistered: false,
      registeredCount: activity.registeredCount - 1,
    );
  }

  void _updateActivity(String id, {bool? isRegistered, int? registeredCount}) {
    final i = activities.indexWhere((a) => a.id == id);
    if (i != -1) {
      final a = activities[i];
      activities[i] = CommunityActivity(
        id: a.id,
        title: a.title,
        description: a.description,
        imageUrl: a.imageUrl,
        eventDate: a.eventDate,
        location: a.location,
        registrationDeadline: a.registrationDeadline,
        maxParticipants: a.maxParticipants,
        registeredCount: registeredCount ?? a.registeredCount,
        isDeleted: a.isDeleted,
        isArchived: a.isArchived,
        isRegistered: isRegistered ?? a.isRegistered,
        createdBy: a.createdBy,
        createdAt: a.createdAt,
      );
      notifyListeners();
    }
  }
}
