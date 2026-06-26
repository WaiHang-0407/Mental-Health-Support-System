import '../models/affirmation.dart';
import '../repositories/affirmations_repository.dart';

class AffirmationsService {
  AffirmationsService({AffirmationsRepository? affirmationsRepository})
      : _affirmationsRepository =
            affirmationsRepository ?? AffirmationsRepository();

  final AffirmationsRepository _affirmationsRepository;

  Future<List<Affirmation>> fetchAffirmations() {
    return _affirmationsRepository.fetchAffirmations();
  }

  Future<void> createAffirmation({
    required String text,
    required String createdBy,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter affirmation text.');
    }

    return _affirmationsRepository.createAffirmation(
      text: trimmed,
      createdBy: createdBy,
    );
  }

  Future<void> updateAffirmation({
    required String affirmationId,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Enter affirmation text.');
    }

    return _affirmationsRepository.updateAffirmation(
      affirmationId: affirmationId,
      text: trimmed,
    );
  }

  Future<void> removeAffirmation(String affirmationId) {
    return _affirmationsRepository.removeAffirmation(affirmationId);
  }
}
