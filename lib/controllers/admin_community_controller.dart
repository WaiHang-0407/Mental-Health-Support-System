import 'package:flutter/foundation.dart';

import '../models/admin_community_post.dart';
import '../services/admin_activity_logs_service.dart';
import '../services/admin_community_service.dart';

class AdminCommunityController extends ChangeNotifier {
  AdminCommunityController({
    AdminCommunityService? communityService,
    AdminActivityLogsService? adminActivityLogsService,
  }) : _communityService = communityService ?? AdminCommunityService(),
       _adminActivityLogsService =
           adminActivityLogsService ?? AdminActivityLogsService();

  final AdminCommunityService _communityService;
  final AdminActivityLogsService _adminActivityLogsService;

  bool _isLoading = false;
  bool _isLoadingReports = false;
  bool _isModerating = false;
  String? _errorMessage;
  String? _reportsErrorMessage;
  List<AdminCommunityPost> _posts = const [];
  List<AdminCommunityReport> _reports = const [];

  bool get isLoading => _isLoading;
  bool get isLoadingReports => _isLoadingReports;
  bool get isModerating => _isModerating;
  String? get errorMessage => _errorMessage;
  String? get reportsErrorMessage => _reportsErrorMessage;
  List<AdminCommunityPost> get posts => _posts;
  List<AdminCommunityReport> get reports => _reports;

  int get activeCount => _posts.where((post) => post.status == 'Active').length;
  int get archivedCount =>
      _posts.where((post) => post.status == 'Archived').length;
  int get deletedCount =>
      _posts.where((post) => post.status == 'Deleted').length;
  int get pendingReportCount =>
      _reports.where((report) => report.status == 'pending').length;

  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _posts = await _communityService.fetchPosts();
    } catch (_) {
      _errorMessage = 'Unable to load community posts.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCommunity() async {
    await Future.wait([loadPosts(), loadReports()]);
  }

  Future<void> loadReports() async {
    _isLoadingReports = true;
    _reportsErrorMessage = null;
    notifyListeners();

    try {
      _reports = await _communityService.fetchReports();
    } catch (_) {
      _reportsErrorMessage = 'Unable to load reports.';
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  Future<AdminCommunityPostDetails> loadPostDetails(AdminCommunityPost post) {
    return _communityService.fetchPostDetails(post);
  }

  Future<bool> archivePost(String postId) async {
    return _runModerationAction(
      () => _communityService.archivePost(postId),
      action: 'community_post_archived',
      targetType: 'post',
      targetId: postId,
    );
  }

  Future<bool> unarchivePost(String postId) async {
    return _runModerationAction(
      () => _communityService.unarchivePost(postId),
      action: 'community_post_unarchived',
      targetType: 'post',
      targetId: postId,
    );
  }

  Future<bool> archiveComment(String commentId) async {
    return _runModerationAction(
      () => _communityService.archiveComment(commentId),
      action: 'community_comment_archived',
      targetType: 'comment',
      targetId: commentId,
    );
  }

  Future<bool> unarchiveComment(String commentId) async {
    return _runModerationAction(
      () => _communityService.unarchiveComment(commentId),
      action: 'community_comment_unarchived',
      targetType: 'comment',
      targetId: commentId,
    );
  }

  Future<bool> sendWarning(AdminUserWarning warning) async {
    return _runModerationAction(
      () => _communityService.sendWarning(warning),
      action: 'community_warning_sent',
      targetType: warning.targetType,
      targetId: warning.targetId,
    );
  }

  Future<bool> archivePostWithWarning(AdminUserWarning warning) {
    return _runModerationAction(
      () async {
        await _communityService.archivePost(warning.targetId);
        await _communityService.sendWarning(warning);
      },
      action: 'community_post_archived_warning_sent',
      targetType: 'post',
      targetId: warning.targetId,
    );
  }

  Future<bool> archiveCommentWithWarning(AdminUserWarning warning) {
    return _runModerationAction(
      () async {
        await _communityService.archiveComment(warning.targetId);
        await _communityService.sendWarning(warning);
      },
      action: 'community_comment_archived_warning_sent',
      targetType: 'comment',
      targetId: warning.targetId,
    );
  }

  Future<bool> dismissReport(String reportId, {String? note}) {
    return _runModerationAction(
      () => _communityService.resolveReport(
        reportId: reportId,
        status: 'dismissed',
        resolutionAction: 'dismissed',
        resolutionNote: note,
      ),
      action: 'community_report_dismissed',
      targetType: 'report',
      targetId: reportId,
    );
  }

  Future<bool> markReportReviewed(String reportId, {String? note}) {
    return _runModerationAction(
      () => _communityService.resolveReport(
        reportId: reportId,
        status: 'reviewed',
        resolutionAction: 'reviewed_no_action',
        resolutionNote: note,
      ),
      action: 'community_report_reviewed',
      targetType: 'report',
      targetId: reportId,
    );
  }

  Future<bool> archiveAndResolveReport(AdminCommunityReport report) {
    return _runModerationAction(
      () async {
        if (report.postId != null) {
          await _communityService.archivePost(report.postId!);
        } else if (report.commentId != null) {
          await _communityService.archiveComment(report.commentId!);
        }
        await _communityService.resolveReport(
          reportId: report.id,
          status: 'reviewed',
          resolutionAction: 'content_archived',
          resolutionNote: 'Reported ${report.targetType.toLowerCase()} archived.',
        );
      },
      action: 'community_report_content_archived',
      targetType: 'report',
      targetId: report.id,
    );
  }

  Future<bool> unarchiveReportedContent(AdminCommunityReport report) {
    return _runModerationAction(
      () async {
        if (report.postId != null) {
          await _communityService.unarchivePost(report.postId!);
        } else if (report.commentId != null) {
          await _communityService.unarchiveComment(report.commentId!);
        }
        await _communityService.resolveReport(
          reportId: report.id,
          status: 'reviewed',
          resolutionAction: 'content_unarchived',
          resolutionNote:
              'Reported ${report.targetType.toLowerCase()} was unarchived by admin.',
        );
      },
      action: 'community_report_content_unarchived',
      targetType: 'report',
      targetId: report.id,
    );
  }

  Future<bool> warnAndResolveReport(
    AdminCommunityReport report,
    AdminUserWarning warning, {
    required bool archiveContent,
  }) {
    return _runModerationAction(
      () async {
        await _communityService.sendWarning(warning);
        if (archiveContent) {
          if (report.postId != null) {
            await _communityService.archivePost(report.postId!);
          } else if (report.commentId != null) {
            await _communityService.archiveComment(report.commentId!);
          }
        }
        await _communityService.resolveReport(
          reportId: report.id,
          status: 'reviewed',
          resolutionAction: archiveContent
              ? 'content_archived_warning_sent'
              : 'warning_sent',
          resolutionNote: warning.description,
        );
      },
      action: archiveContent
          ? 'community_report_archived_warning_sent'
          : 'community_report_warning_sent',
      targetType: 'report',
      targetId: report.id,
    );
  }

  Future<bool> _runModerationAction(
    Future<void> Function() actionCallback, {
    required String action,
    required String targetType,
    required String targetId,
  }) async {
    _isModerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await actionCallback();
      await _adminActivityLogsService.log(
        action: action,
        targetType: targetType,
        targetId: targetId,
      );
      await loadCommunity();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to complete moderation action.';
      return false;
    } finally {
      _isModerating = false;
      notifyListeners();
    }
  }
}
