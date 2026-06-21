import '../models/post.dart';
import '../models/user_activity_log.dart';
import 'comment_table_repository.dart';
import 'patient_follows_table_repository.dart';
import 'post_table_repository.dart';
import 'saved_posts_table_repository.dart';
import 'user_activity_logs_table_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final supabase = Supabase.instance.client;
  final _postRepo = PostRepository();
  final _commentRepo = CommentRepository();
  final _savedPostsTable = SavedPostsTableRepository();
  final _activityLogsTable = UserActivityLogsTableRepository();
  final _patientFollowsTable = PatientFollowsTableRepository();

  String get _uid => supabase.auth.currentUser!.id;

  Future<List<Post>> getMyPosts() {
    return _postRepo.getPostsByPatient(_uid, archived: false);
  }

  Future<List<Post>> getMyArchivedPosts() {
    return _postRepo.getPostsByPatient(_uid, archived: true);
  }

  Future<List<Post>> getMySavedPosts() async {
    final savedData = await _savedPostsTable.findSavedPostIds(_uid);
    if (savedData.isEmpty) return [];

    final postIds = savedData.map((s) => s['post_id']).toList();
    return _postRepo.getPostsByIds(postIds, archived: false, isSaved: true);
  }

  Future<List<UserActivityLog>> getMyActivityLogs() async {
    final data = await _activityLogsTable.getByPatient(_uid);
    return data.map((e) => UserActivityLog.fromMap(e)).toList();
  }

  Future<List<Post>> getPublicPostsByPatient(String patientId) {
    return _postRepo.getPostsByPatient(patientId, archived: false);
  }

  Future<Post?> getPostByIdForActivity(String postId) {
    return _postRepo.getPostByIdForActivity(postId);
  }

  Future<String?> getPostIdForCommentActivity(String commentId) {
    return _commentRepo.getPostIdForCommentActivity(commentId);
  }

  Future<bool> isFollowing(String patientId) async {
    return _patientFollowsTable.exists(_uid, patientId);
  }

  Future<void> followPatient(String patientId) async {
    await _patientFollowsTable.upsert(_uid, patientId);
  }

  Future<void> unfollowPatient(String patientId) async {
    await _patientFollowsTable.delete(_uid, patientId);
  }

  Future<int> getFollowerCount(String patientId) async {
    return _patientFollowsTable.followerCount(patientId);
  }

  Future<int> getFollowingCount(String patientId) async {
    return _patientFollowsTable.followingCount(patientId);
  }
}
