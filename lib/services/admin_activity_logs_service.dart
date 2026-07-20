import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/admin_activity_log.dart';
import '../repositories/admin_activity_logs_repository.dart';

class AdminActivityLogsService {
  AdminActivityLogsService({AdminActivityLogsRepository? logsRepository})
      : _logsRepository = logsRepository ?? AdminActivityLogsRepository();

  final AdminActivityLogsRepository _logsRepository;

  Future<List<AdminActivityLog>> fetchLogs({int limit = 100}) {
    return _logsRepository.fetchLogs(limit: limit);
  }

  Future<AdminActivityLogTargetDetails?> fetchTargetDetails(
    AdminActivityLog log,
  ) {
    return _logsRepository.fetchTargetDetails(log);
  }

  Future<void> log({
    required String action,
    String? targetType,
    String? targetId,
  }) async {
    final adminId = Supabase.instance.client.auth.currentUser?.id;
    if (adminId == null) return;

    try {
      await _logsRepository.insert(
        AdminActivityLog(
          adminId: adminId,
          action: action,
          targetType: targetType,
          targetId: targetId,
        ),
      );
    } catch (error) {
      debugPrint('Admin activity log error: $error');
    }
  }
}
