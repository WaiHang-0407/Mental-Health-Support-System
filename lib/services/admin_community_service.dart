import '../models/admin_community_post.dart';
import '../repositories/admin_community_repository.dart';

class AdminCommunityService {
  AdminCommunityService({AdminCommunityRepository? communityRepository})
    : _communityRepository = communityRepository ?? AdminCommunityRepository();

  final AdminCommunityRepository _communityRepository;

  Future<List<AdminCommunityPost>> fetchPosts() {
    return _communityRepository.fetchPosts();
  }

  Future<AdminCommunityPostDetails> fetchPostDetails(AdminCommunityPost post) {
    return _communityRepository.fetchPostDetails(post);
  }

  Future<List<AdminCommunityReport>> fetchReports() {
    return _communityRepository.fetchReports();
  }

  Future<void> archivePost(String postId) {
    return _communityRepository.archivePost(postId);
  }

  Future<void> unarchivePost(String postId) {
    return _communityRepository.unarchivePost(postId);
  }

  Future<void> archiveComment(String commentId) {
    return _communityRepository.archiveComment(commentId);
  }

  Future<void> unarchiveComment(String commentId) {
    return _communityRepository.unarchiveComment(commentId);
  }

  Future<void> sendWarning(AdminUserWarning warning) {
    return _communityRepository.sendWarning(warning);
  }

  Future<void> resolveReport({
    required String reportId,
    required String status,
    required String resolutionAction,
    String? resolutionNote,
  }) {
    return _communityRepository.resolveReport(
      reportId: reportId,
      status: status,
      resolutionAction: resolutionAction,
      resolutionNote: resolutionNote,
    );
  }
}
