import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/database_tables.dart';
import '../models/community_activity.dart';

class CommunityActivitiesRepository {
  CommunityActivitiesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<CommunityActivity>> fetchActivities() async {
    final rows = await _client
        .from(DatabaseTables.activities)
        .select(
          'id, title, description, location, event_date, registration_deadline, '
          'max_participants, is_deleted, is_archived, created_at',
        )
        .order('created_at', ascending: false);

    final sponsorships = await fetchSponsorships();
    final sponsorshipsById = {
      for (final sponsorship in sponsorships) sponsorship.id: sponsorship,
    };
    final linksByActivityId = await _sponsorshipIdsByActivityId();

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        CommunityActivity.fromJson({
          ...row,
          'sponsorships': [
            for (final sponsorshipId
                in linksByActivityId[row['id'] as String] ?? const <String>[])
              if (sponsorshipsById[sponsorshipId] != null)
                _sponsorshipToJson(sponsorshipsById[sponsorshipId]!),
          ],
        }),
    ];
  }

  Future<List<ActivitySponsorship>> fetchSponsorships() async {
    final rows = await _client
        .from(DatabaseTables.sponsorships)
        .select(
          'id, activity_id, sponsor_name, description, is_deleted, '
          'is_archived, created_at, sponsorship_products(id, sponsorship_id, '
          'name, description, image_url, is_deleted, is_archived, created_at)',
        )
        .order('created_at', ascending: false);

    final activityIdsBySponsorshipId = await _activityIdsBySponsorshipId();

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        ActivitySponsorship.fromJson({
          ...row,
          'activity_sponsorships': [
            for (final activityId
                in activityIdsBySponsorshipId[row['id'] as String] ??
                    const <String>[])
              {'activity_id': activityId},
          ],
        }),
    ];
  }

  Future<List<ActivityParticipant>> fetchParticipants(String activityId) async {
    final registrations = await _client
        .from(DatabaseTables.activityRegistrations)
        .select('id, patient_id, is_cancelled, created_at')
        .eq('activity_id', activityId)
        .order('created_at', ascending: false);

    final registrationRows = registrations.cast<Map<String, dynamic>>();
    if (registrationRows.isEmpty) {
      return const [];
    }

    final patientIds = [
      for (final row in registrationRows) row['patient_id'] as String,
    ];
    final patients = await _client
        .from(DatabaseTables.patients)
        .select(
          'id, name, gender, dob, phoneno, condition, fav_animal, '
          'fav_activity, avatar_url',
        )
        .inFilter('id', patientIds);

    final patientRows = patients.cast<Map<String, dynamic>>();
    final patientsById = {
      for (final patient in patientRows) patient['id'] as String: patient,
    };

    return [
      for (final row in registrationRows)
        ActivityParticipant.fromJson({
          ...row,
          'patients': patientsById[row['patient_id'] as String],
        }),
    ];
  }

  Future<void> createActivity(CreateCommunityActivityInput input) async {
    final activity = await _client
        .from(DatabaseTables.activities)
        .insert({
          'title': input.title,
          'description': input.description,
          'location': input.venue,
          'event_date': input.eventDate.toIso8601String(),
          'registration_deadline':
              input.registrationDeadline.toIso8601String(),
          'max_participants': input.maxParticipants,
          'created_by': input.createdBy,
        })
        .select('id')
        .single();

    final activityId = activity['id'] as String;
    if (input.sponsorshipIds.isNotEmpty) {
      await attachSponsorships(
        activityId: activityId,
        sponsorshipIds: input.sponsorshipIds,
      );
    }
  }

  Future<void> createSponsorship({
    required SponsorshipDraft sponsorship,
  }) async {
    final sponsorshipRow = await _client
        .from(DatabaseTables.sponsorships)
        .insert({
          'sponsor_name': sponsorship.sponsorName,
          'description': sponsorship.description,
        })
        .select('id')
        .single();

    final sponsorshipId = sponsorshipRow['id'] as String;
    if (sponsorship.products.isEmpty) {
      return;
    }

    await _client.from(DatabaseTables.sponsorshipProducts).insert([
      for (final product in sponsorship.products)
        {
          'sponsorship_id': sponsorshipId,
          'name': product.name,
          'description': product.description,
          'image_url': await _productImageUrl(sponsorshipId, product),
        },
    ]);
  }

  Future<void> updateSponsorship({
    required String sponsorshipId,
    required SponsorshipDraft sponsorship,
  }) async {
    await _client.from(DatabaseTables.sponsorships).update({
      'sponsor_name': sponsorship.sponsorName,
      'description': sponsorship.description,
    }).eq('id', sponsorshipId);

    if (sponsorship.products.isEmpty) {
      return;
    }

    await _client.from(DatabaseTables.sponsorshipProducts).insert([
      for (final product in sponsorship.products)
        {
          'sponsorship_id': sponsorshipId,
          'name': product.name,
          'description': product.description,
          'image_url': await _productImageUrl(sponsorshipId, product),
        },
    ]);
  }

  Future<void> attachSponsorships({
    required String activityId,
    required List<String> sponsorshipIds,
  }) {
    return _client.from(DatabaseTables.activitySponsorships).upsert(
      [
        for (final sponsorshipId in sponsorshipIds)
          {
            'activity_id': activityId,
            'sponsorship_id': sponsorshipId,
          },
      ],
      onConflict: 'activity_id,sponsorship_id',
    );
  }

  Future<void> updateActivity({
    required String activityId,
    required CreateCommunityActivityInput input,
  }) async {
    await _client.from(DatabaseTables.activities).update({
      'title': input.title,
      'description': input.description,
      'location': input.venue,
      'event_date': input.eventDate.toIso8601String(),
      'registration_deadline': input.registrationDeadline.toIso8601String(),
      'max_participants': input.maxParticipants,
    }).eq('id', activityId);

    await replaceActivitySponsorships(
      activityId: activityId,
      sponsorshipIds: input.sponsorshipIds,
    );
  }

  Future<void> replaceActivitySponsorships({
    required String activityId,
    required List<String> sponsorshipIds,
  }) async {
    await _client
        .from(DatabaseTables.activitySponsorships)
        .delete()
        .eq('activity_id', activityId);

    if (sponsorshipIds.isEmpty) {
      return;
    }

    await attachSponsorships(
      activityId: activityId,
      sponsorshipIds: sponsorshipIds,
    );
  }

  Future<void> archiveActivity(String activityId) {
    return _client
        .from(DatabaseTables.activities)
        .update({'is_archived': true})
        .eq('id', activityId);
  }

  Future<void> unarchiveActivity(String activityId) {
    return _client
        .from(DatabaseTables.activities)
        .update({'is_archived': false})
        .eq('id', activityId);
  }

  Future<void> deleteActivity(String activityId) async {
    await _client
        .from(DatabaseTables.activities)
        .update({'is_deleted': true, 'is_archived': false})
        .eq('id', activityId);

    final sponsorshipIds = await _sponsorshipIdsForActivity(activityId);
    if (sponsorshipIds.isNotEmpty) {
      await _client
          .from(DatabaseTables.activitySponsorships)
          .delete()
          .eq('activity_id', activityId);
    }
  }

  Future<void> archiveSponsorship(String sponsorshipId) {
    return _client
        .from(DatabaseTables.sponsorships)
        .update({'is_archived': true})
        .eq('id', sponsorshipId);
  }

  Future<void> unarchiveSponsorship(String sponsorshipId) {
    return _client
        .from(DatabaseTables.sponsorships)
        .update({'is_archived': false})
        .eq('id', sponsorshipId);
  }

  Future<void> deleteSponsorship(String sponsorshipId) async {
    await _client
        .from(DatabaseTables.sponsorships)
        .update({'is_deleted': true, 'is_archived': false})
        .eq('id', sponsorshipId);
    await _client
        .from(DatabaseTables.sponsorshipProducts)
        .update({'is_deleted': true, 'is_archived': false})
        .eq('sponsorship_id', sponsorshipId);
  }

  Future<void> archiveProduct(String productId) {
    return _client
        .from(DatabaseTables.sponsorshipProducts)
        .update({'is_archived': true})
        .eq('id', productId);
  }

  Future<void> unarchiveProduct(String productId) {
    return _client
        .from(DatabaseTables.sponsorshipProducts)
        .update({'is_archived': false})
        .eq('id', productId);
  }

  Future<void> deleteProduct(String productId) {
    return _client
        .from(DatabaseTables.sponsorshipProducts)
        .update({'is_deleted': true, 'is_archived': false})
        .eq('id', productId);
  }

  Future<void> updateProduct({
    required String productId,
    required String sponsorshipId,
    required UpdateSponsorshipProductInput input,
  }) async {
    final imageUrl = await _updatedProductImageUrl(sponsorshipId, input);

    await _client.from(DatabaseTables.sponsorshipProducts).update({
      'name': input.name,
      'description': input.description,
      'image_url': imageUrl,
    }).eq('id', productId);
  }

  Future<List<String>> _sponsorshipIdsForActivity(String activityId) async {
    final rows = await _client
        .from(DatabaseTables.activitySponsorships)
        .select('sponsorship_id')
        .eq('activity_id', activityId);

    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        row['sponsorship_id'] as String,
    ];
  }

  Future<Map<String, List<String>>> _sponsorshipIdsByActivityId() async {
    final rows = await _client
        .from(DatabaseTables.activitySponsorships)
        .select('activity_id, sponsorship_id');

    final result = <String, List<String>>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final activityId = row['activity_id'] as String;
      final sponsorshipId = row['sponsorship_id'] as String;
      result.putIfAbsent(activityId, () => []).add(sponsorshipId);
    }
    return result;
  }

  Future<Map<String, List<String>>> _activityIdsBySponsorshipId() async {
    final rows = await _client
        .from(DatabaseTables.activitySponsorships)
        .select('activity_id, sponsorship_id');

    final result = <String, List<String>>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final sponsorshipId = row['sponsorship_id'] as String;
      final activityId = row['activity_id'] as String;
      result.putIfAbsent(sponsorshipId, () => []).add(activityId);
    }
    return result;
  }

  Map<String, dynamic> _sponsorshipToJson(ActivitySponsorship sponsorship) {
    return {
      'id': sponsorship.id,
      'sponsor_name': sponsorship.sponsorName,
      'description': sponsorship.description,
      'is_deleted': sponsorship.isDeleted,
      'is_archived': sponsorship.isArchived,
      'created_at': sponsorship.createdAt?.toIso8601String(),
      'activity_sponsorships': [
        for (final activityId in sponsorship.activityIds)
          {'activity_id': activityId},
      ],
      'sponsorship_products': [
        for (final product in sponsorship.products)
          {
            'id': product.id,
            'sponsorship_id': product.sponsorshipId,
            'name': product.name,
            'description': product.description,
            'image_url': product.imageUrl,
            'is_deleted': product.isDeleted,
            'is_archived': product.isArchived,
            'created_at': product.createdAt?.toIso8601String(),
          },
      ],
    };
  }

  Future<String?> _productImageUrl(
    String sponsorshipId,
    SponsorshipProductDraft product,
  ) async {
    final bytes = product.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      return product.imageUrl;
    }

    final fileName = _safeFileName(product.imageFileName ?? 'product-image');
    final path =
        '$sponsorshipId/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(DatabaseTables.sponsorshipProductImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: product.imageMimeType ?? 'application/octet-stream',
            upsert: true,
          ),
        );

    return _client.storage
        .from(DatabaseTables.sponsorshipProductImagesBucket)
        .getPublicUrl(path);
  }

  Future<String?> _updatedProductImageUrl(
    String sponsorshipId,
    UpdateSponsorshipProductInput input,
  ) async {
    final bytes = input.imageBytes;
    if (bytes == null || bytes.isEmpty) {
      return input.imageUrl;
    }

    final fileName = _safeFileName(input.imageFileName ?? 'product-image');
    final path =
        '$sponsorshipId/${DateTime.now().microsecondsSinceEpoch}_$fileName';

    await _client.storage
        .from(DatabaseTables.sponsorshipProductImagesBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: input.imageMimeType ?? 'application/octet-stream',
            upsert: true,
          ),
        );

    return _client.storage
        .from(DatabaseTables.sponsorshipProductImagesBucket)
        .getPublicUrl(path);
  }

  String _safeFileName(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
