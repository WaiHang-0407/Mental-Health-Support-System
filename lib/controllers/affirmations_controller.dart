import 'package:flutter/foundation.dart';

import '../models/affirmation.dart';
import '../services/admin_activity_logs_service.dart';
import '../services/affirmations_service.dart';

class AffirmationsController extends ChangeNotifier {
  AffirmationsController({
    AffirmationsService? affirmationsService,
    AdminActivityLogsService? adminActivityLogsService,
  })  : _affirmationsService = affirmationsService ?? AffirmationsService(),
        _adminActivityLogsService =
            adminActivityLogsService ?? AdminActivityLogsService();

  final AffirmationsService _affirmationsService;
  final AdminActivityLogsService _adminActivityLogsService;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<Affirmation> _affirmations = const [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<Affirmation> get affirmations => _affirmations;

  Future<void> loadAffirmations() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _affirmations = await _affirmationsService.fetchAffirmations();
    } catch (_) {
      _errorMessage = 'Unable to load affirmations.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAffirmation({
    required String text,
    required String createdBy,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _affirmationsService.createAffirmation(
        text: text,
        createdBy: createdBy,
      );
      await _adminActivityLogsService.log(
        action: 'affirmation_created',
        targetType: 'affirmation',
      );
      await loadAffirmations();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to add affirmation.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAffirmation({
    required Affirmation affirmation,
    required String text,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _affirmationsService.updateAffirmation(
        affirmationId: affirmation.id,
        text: text,
      );
      await _adminActivityLogsService.log(
        action: 'affirmation_updated',
        targetType: 'affirmation',
        targetId: affirmation.id,
      );
      await loadAffirmations();
      return true;
    } on ArgumentError catch (error) {
      _errorMessage = error.message as String;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update affirmation.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> removeAffirmation(Affirmation affirmation) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _affirmationsService.removeAffirmation(affirmation.id);
      await _adminActivityLogsService.log(
        action: 'affirmation_removed',
        targetType: 'affirmation',
        targetId: affirmation.id,
      );
      await loadAffirmations();
    } catch (_) {
      _errorMessage = 'Unable to remove affirmation.';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
