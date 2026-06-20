import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';
import '../models/post.dart';
import '../models/user_activity_log.dart';
import '../repositories/patient_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/post_repository.dart';

class UserProfileController extends ChangeNotifier {
  final PatientRepository _patientRepo = PatientRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final PostRepository _postRepo = PostRepository();

  PatientModel? patient;
  List<Post> myPosts = [];
  List<Post> savedPosts = [];
  List<Post> archivedPosts = [];
  List<UserActivityLog> activityLogs = [];

  bool isLoading = false;
  bool isUploadingAvatar = false;
  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();
    try {
      patient = await _patientRepo.getPatientById(_uid);
      await Future.wait([
        _loadMyPosts(),
        _loadSavedPosts(),
        _loadArchivedPosts(),
        _loadActivityLogs(),
      ]);
    } catch (e) {
      debugPrint('loadProfile error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadMyPosts() async {
    myPosts = await _profileRepo.getMyPosts();
  }

  Future<void> _loadSavedPosts() async {
    savedPosts = await _profileRepo.getMySavedPosts();
  }

  Future<void> _loadArchivedPosts() async {
    archivedPosts = await _profileRepo.getMyArchivedPosts();
  }

  Future<void> _loadActivityLogs() async {
    activityLogs = await _profileRepo.getMyActivityLogs();
  }

  Future<Post?> getPostByIdForActivity(String postId) {
    return _profileRepo.getPostByIdForActivity(postId);
  }

  Future<String?> getPostIdForCommentActivity(String commentId) {
    return _profileRepo.getPostIdForCommentActivity(commentId);
  }

  Future<void> uploadAvatar(File file) async {
    isUploadingAvatar = true;
    notifyListeners();
    try {
      final url = await _patientRepo.uploadAvatar(file, _uid);
      if (url != null) {
        await _patientRepo.updateAvatar(_uid, url);
        await _log('avatar_updated', targetType: 'profile');
        patient = await _patientRepo.getPatientById(_uid);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('uploadAvatar error: $e');
    } finally {
      isUploadingAvatar = false;
      notifyListeners();
    }
  }

  Future<void> toggleArchive(Post post) async {
    try {
      await _postRepo.toggleArchive(post.id, post.isArchived);
      if (post.isArchived) {
        // Unarchiving — move to myPosts
        archivedPosts.removeWhere((p) => p.id == post.id);
        await _loadMyPosts();
      } else {
        // Archiving — move to archivedPosts
        myPosts.removeWhere((p) => p.id == post.id);
        savedPosts.removeWhere((p) => p.id == post.id);
        await _loadArchivedPosts();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('toggleArchive error: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _postRepo.softDeletePost(postId);
      myPosts.removeWhere((p) => p.id == postId);
      archivedPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('deletePost error: $e');
    }
  }

  // Keep old saveProfile for name_query compatibility
  Future<void> saveProfile({
    required String name,
    required String gender,
    required DateTime dob,
  }) async {
    await _patientRepo.updateProfile(_uid, {
      'name': name,
      'gender': gender,
      'dob': dob.toIso8601String().split('T').first,
    });
    await _log('profile_updated', targetType: 'profile');
  }

  Future<void> savePersonalization({
    required List<String> conditions,
    required String favAnimal,
    required String favActivity,
  }) async {
    await _patientRepo.updatePersonalization(_uid, {
      'condition': conditions.join(','),
      'fav_animal': favAnimal,
      'fav_activity': favActivity,
    });
    await _log('personalization_updated', targetType: 'profile');
  }

  Future<void> _log(
    String action, {
    String? targetType,
    String? targetId,
  }) async {
    await Supabase.instance.client.from('user_activity_logs').insert({
      'patient_id': _uid,
      'action': action,
      if (targetType != null) 'target_type': targetType,
      if (targetId != null) 'target_id': targetId,
    });
  }
}
