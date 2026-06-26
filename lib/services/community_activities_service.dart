import '../models/community_activity.dart';
import '../repositories/community_activities_repository.dart';

class CommunityActivitiesService {
  CommunityActivitiesService({
    CommunityActivitiesRepository? communityActivitiesRepository,
  }) : _communityActivitiesRepository =
            communityActivitiesRepository ?? CommunityActivitiesRepository();

  final CommunityActivitiesRepository _communityActivitiesRepository;

  DateTime minimumEventDate({DateTime? now}) {
    final base = now ?? DateTime.now();
    return DateTime(base.year, base.month, base.day).add(const Duration(days: 10));
  }

  DateTime registrationDeadlineFor(DateTime eventDate) {
    return DateTime(eventDate.year, eventDate.month, eventDate.day)
        .subtract(const Duration(days: 2));
  }

  void validateActivityInput(CreateCommunityActivityInput input) {
    if (input.title.trim().isEmpty) {
      throw ArgumentError('Enter the activity title.');
    }
    if (input.description.trim().isEmpty) {
      throw ArgumentError('Enter the activity description.');
    }
    if (input.venue.trim().isEmpty) {
      throw ArgumentError('Enter the activity venue.');
    }

    final earliestDate = minimumEventDate();
    final eventDateOnly = DateTime(
      input.eventDate.year,
      input.eventDate.month,
      input.eventDate.day,
    );
    if (eventDateOnly.isBefore(earliestDate)) {
      throw ArgumentError('Activity date must be at least 10 days from today.');
    }

    final requiredDeadline = registrationDeadlineFor(input.eventDate);
    final deadlineOnly = DateTime(
      input.registrationDeadline.year,
      input.registrationDeadline.month,
      input.registrationDeadline.day,
    );
    if (deadlineOnly != requiredDeadline) {
      throw ArgumentError(
        'Registration deadline must be 2 days before the activity date.',
      );
    }
  }

  Future<List<CommunityActivity>> fetchActivities() {
    return _communityActivitiesRepository.fetchActivities();
  }

  Future<List<ActivitySponsorship>> fetchSponsorships() {
    return _communityActivitiesRepository.fetchSponsorships();
  }

  Future<List<ActivityParticipant>> fetchParticipants(String activityId) {
    return _communityActivitiesRepository.fetchParticipants(activityId);
  }

  Future<void> createActivity(CreateCommunityActivityInput input) {
    validateActivityInput(input);
    return _communityActivitiesRepository.createActivity(input);
  }

  void validateSponsorshipDraft(SponsorshipDraft sponsorship) {
    if (sponsorship.sponsorName.trim().isEmpty) {
      throw ArgumentError('Enter the sponsor name.');
    }
    for (final product in sponsorship.products) {
      if (product.name.trim().isEmpty) {
        throw ArgumentError('Enter each product name.');
      }
    }
  }

  Future<void> createSponsorship({
    required SponsorshipDraft sponsorship,
  }) {
    validateSponsorshipDraft(sponsorship);
    return _communityActivitiesRepository.createSponsorship(
      sponsorship: sponsorship,
    );
  }

  Future<void> updateActivity({
    required String activityId,
    required CreateCommunityActivityInput input,
  }) {
    validateActivityInput(input);
    return _communityActivitiesRepository.updateActivity(
      activityId: activityId,
      input: input,
    );
  }

  Future<void> archiveActivity(String activityId) {
    return _communityActivitiesRepository.archiveActivity(activityId);
  }

  Future<void> unarchiveActivity(String activityId) {
    return _communityActivitiesRepository.unarchiveActivity(activityId);
  }

  Future<void> deleteActivity(String activityId) {
    return _communityActivitiesRepository.deleteActivity(activityId);
  }

  Future<void> archiveSponsorship(String sponsorshipId) {
    return _communityActivitiesRepository.archiveSponsorship(sponsorshipId);
  }

  Future<void> unarchiveSponsorship(String sponsorshipId) {
    return _communityActivitiesRepository.unarchiveSponsorship(sponsorshipId);
  }

  Future<void> deleteSponsorship(String sponsorshipId) {
    return _communityActivitiesRepository.deleteSponsorship(sponsorshipId);
  }

  Future<void> archiveProduct(String productId) {
    return _communityActivitiesRepository.archiveProduct(productId);
  }

  Future<void> deleteProduct(String productId) {
    return _communityActivitiesRepository.deleteProduct(productId);
  }

  Future<void> updateProduct({
    required String productId,
    required String sponsorshipId,
    required UpdateSponsorshipProductInput input,
  }) {
    if (input.name.trim().isEmpty) {
      throw ArgumentError('Enter the product name.');
    }

    return _communityActivitiesRepository.updateProduct(
      productId: productId,
      sponsorshipId: sponsorshipId,
      input: input,
    );
  }
}
