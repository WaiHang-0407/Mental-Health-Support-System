import '../models/post.dart';
import '../models/patient.dart';
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

  Future<List<PatientModel>> getFollowers(String patientId) async {
    final data = await supabase
        .from('patient_follows')
        .select('follower_id')
        .eq('following_id', patientId);

    final ids = (data as List)
        .map((item) => item['follower_id']?.toString())
        .whereType<String>()
        .toList();

    return _getPatientsByIds(ids);
  }

  Future<List<PatientModel>> getFollowing(String patientId) async {
    final data = await supabase
        .from('patient_follows')
        .select('following_id')
        .eq('follower_id', patientId);

    final ids = (data as List)
        .map((item) => item['following_id']?.toString())
        .whereType<String>()
        .toList();

    return _getPatientsByIds(ids);
  }

  Future<List<PatientModel>> _getPatientsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final data = await supabase
        .from('patients')
        .select(
          'id, name, gender, dob, phoneno, condition, fav_animal, fav_activity, avatar_url',
        )
        .inFilter('id', ids);

    final patients = (data as List)
        .map((item) => PatientModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    final order = {for (var i = 0; i < ids.length; i++) ids[i]: i};
    patients.sort((a, b) => (order[a.id] ?? 0).compareTo(order[b.id] ?? 0));
    return patients;
  }
}
