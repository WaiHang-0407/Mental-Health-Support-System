import 'package:flutter/foundation.dart';

import '../models/admin_activity_log.dart';
import '../services/admin_activity_logs_service.dart';

class AdminActivityLogsController extends ChangeNotifier {
  AdminActivityLogsController({
    AdminActivityLogsService? adminActivityLogsService,
  }) : _adminActivityLogsService =
            adminActivityLogsService ?? AdminActivityLogsService();

  final AdminActivityLogsService _adminActivityLogsService;

  bool _isLoading = false;
  String? _errorMessage;
  List<AdminActivityLog> _logs = const [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AdminActivityLog> get logs => _logs;

  Future<void> loadLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await _adminActivityLogsService.fetchLogs();
    } catch (_) {
      _errorMessage = 'Unable to load activity logs.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AdminActivityLogTargetDetails?> loadTargetDetails(
    AdminActivityLog log,
  ) {
    return _adminActivityLogsService.fetchTargetDetails(log);
  }
}
