// repositories/post_repository.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post.dart';
import 'hidden_posts_table_repository.dart';
import 'patient_table_repository.dart';
import 'post_likes_table_repository.dart';
import 'reports_table_repository.dart';
import 'saved_posts_table_repository.dart';
import 'user_activity_logs_table_repository.dart';
import 'user_role_repository.dart';

class PostRepository {
  final supabase = Supabase.instance.client;
  final _hiddenPostsTable = HiddenPostsTableRepository();
  final _patientRepo = PatientRepository();
  final _postLikesTable = PostLikesTableRepository();
  final _savedPostsTable = SavedPostsTableRepository();
  final _reportsTable = ReportsTableRepository();
  final _activityLogsTable = UserActivityLogsTableRepository();
  final _userRoleRepo = UserRoleRepository();

  static const _postSelect =
      'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count), users(role)';

  String get _uid => supabase.auth.currentUser!.id;

  Future<List<Post>> getFeed({int page = 0, int limit = 20}) async {
    final from = page * limit;
    final data = await supabase
        .from('posts')
        .select(_postSelect)
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('created_at', ascending: false)
        .range(from, from + limit - 1);

    if ((data as List).isEmpty) return [];

    final hidden = await _hiddenPostsTable.findHiddenPostIds(_uid);
    final hiddenIds = hidden.map((h) => h['post_id']).toSet();
    data.removeWhere((p) => hiddenIds.contains(p['id']));
    if (data.isEmpty) return [];

    final patientIds = data.map((p) => p['patient_id']).toList();
    final patientData = await _patientRepo.findNamesByIds(patientIds);
    final nameMap = {for (final p in patientData) p['id']: p['name']};

    final postIds = data.map((p) => p['id']).toList();
    final likes = await _postLikesTable.findLikedPostIds(_uid, postIds);
    final saves = await _savedPostsTable.findSavedPostIds(
      _uid,
      postIds: postIds,
    );
    final visibleCommentCounts = await _getVisibleCommentCounts(postIds);

    final likedIds = likes.map((l) => l['post_id']).toSet();
    final savedIds = saves.map((s) => s['post_id']).toSet();

    return data.map((p) {
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(p),
        'author_name': nameMap[p['patient_id']] ?? 'Anonymous',
        'author_role': (p['users'] as Map?)?['role']?.toString(),
        'like_count': (p['post_likes'] as List?)?.first?['count'] ?? 0,
        'comment_count': visibleCommentCounts[p['id']] ?? 0,
      };
      return Post.fromMap(
        map,
        isLiked: likedIds.contains(p['id']),
        isSaved: savedIds.contains(p['id']),
      );
    }).toList();
  }

  Future<List<Post>> getMyPosts() async {
    final data = await _getByPatient(_uid);
    if (data.isEmpty) return [];

    final patientData = await _patientRepo.findNameById(_uid);
    final name = patientData?['name'] ?? 'Anonymous';

    return _mapPostsWithVisibleCommentCounts(data, authorName: name);
  }

  Future<List<Post>> getPostsByPatient(
    String patientId, {
    bool? archived,
    bool isSaved = false,
  }) async {
    final data = await _getByPatient(patientId, archived: archived);
    return _mapPostsWithVisibleCommentCounts(
      data,
      authorName: patientId == _uid ? 'You' : 'Anonymous',
      isSaved: isSaved,
    );
  }

  Future<List<Post>> getPostsByIds(
    List ids, {
    bool? archived,
    bool isSaved = false,
  }) async {
    if (ids.isEmpty) return [];
    var query = supabase
        .from('posts')
        .select(_postSelect)
        .inFilter('id', ids)
        .eq('is_deleted', false);
    if (archived != null) query = query.eq('is_archived', archived);

    final data = await query.order('created_at', ascending: false);
    return _mapPostsWithVisibleCommentCounts(data, isSaved: isSaved);
  }

  Future<Post?> getPostByIdForActivity(String postId) async {
    final data = await supabase
        .from('posts')
        .select(_postSelect)
        .eq('id', postId)
        .maybeSingle();
    if (data == null) return null;
    return (await _mapPostsWithVisibleCommentCounts([data])).first;
  }

  Future<void> createPost(
    String content, {
    List<String> imageUrls = const [],
  }) async {
    final post = Post(
      id: '',
      patientId: _uid,
      content: content,
      imageUrls: imageUrls,
      createdAt: DateTime.now(),
    );
    final data = await supabase
        .from('posts')
        .insert(post.toCreateMap())
        .select('id')
        .single();
    await _log('post_created', targetId: data['id']);
  }

  Future<void> softDeletePost(String postId) async {
    await supabase
        .from('posts')
        .update({'is_deleted': true, 'deleted_by': _uid})
        .eq('id', postId);
    await _log('post_deleted', targetId: postId);
  }

  Future<void> toggleArchive(String postId, bool isArchived) async {
    await supabase
        .from('posts')
        .update({'is_archived': !isArchived})
        .eq('id', postId);
    await _log(
      isArchived ? 'post_unarchived' : 'post_archived',
      targetId: postId,
    );
  }

  Future<void> toggleLike(String postId, bool isLiked) async {
    if (isLiked) {
      await _postLikesTable.delete(postId, _uid);
    } else {
      await _postLikesTable.insert(postId, _uid);
      await _log('post_liked', targetId: postId);
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    if (isSaved) {
      await _savedPostsTable.delete(postId, _uid);
      await _log('post_unsaved', targetId: postId);
    } else {
      await _savedPostsTable.insert(postId, _uid);
      await _log('post_saved', targetId: postId);
    }
  }

  Future<void> reportPost({
    required String postId,
    required String postOwnerId,
    required String reason,
  }) async {
    if (postOwnerId == _uid) {
      throw StateError('Users cannot report their own posts.');
    }

    await _reportsTable.insertPostReport(
      reporterId: _uid,
      postId: postId,
      reason: reason,
    );
    await _log('post_reported', targetId: postId);
  }

  Future<void> hidePost(String postId) async {
    await _hiddenPostsTable.upsert(postId, _uid);
  }

  Future<List<String>> uploadPostImages(List<File> files) async {
    final List<String> urls = [];
    for (final file in files) {
      try {
        final fileName =
            '${_uid}_${DateTime.now().millisecondsSinceEpoch}_${urls.length}.jpg';
        await supabase.storage.from('post-images').upload(fileName, file);
        final url = supabase.storage.from('post-images').getPublicUrl(fileName);
        urls.add(url);
      } catch (e) {
        debugPrint('Image upload error: $e');
      }
    }
    return urls;
  }

  Future<List<dynamic>> _getByPatient(String patientId, {bool? archived}) {
    var query = supabase
        .from('posts')
        .select(_postSelect)
        .eq('patient_id', patientId)
        .eq('is_deleted', false);
    if (archived != null) query = query.eq('is_archived', archived);
    return query.order('created_at', ascending: false);
  }

  Future<List<Post>> _mapPostsWithVisibleCommentCounts(
    List data, {
    String authorName = 'Anonymous',
    bool isLiked = false,
    bool isSaved = false,
    Map<String, String?>? authorRoles,
  }) async {
    final postIds = data.map((p) => p['id']).toList();
    final visibleCommentCounts = await _getVisibleCommentCounts(postIds);

    return data.map((p) {
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(p),
        'author_name': authorName,
        'author_role':
            (p['users'] as Map?)?['role']?.toString() ??
            authorRoles?[p['patient_id']] ??
            p['author_role']?.toString(),
        'like_count': (p['post_likes'] as List?)?.first?['count'] ?? 0,
        'comment_count': visibleCommentCounts[p['id']] ?? 0,
      };
      return Post.fromMap(map, isLiked: isLiked, isSaved: isSaved);
    }).toList();
  }

  Future<Map<String, int>> _getVisibleCommentCounts(List postIds) async {
    if (postIds.isEmpty) return {};

    final hidden = await supabase
        .from('hidden_comments')
        .select('comment_id')
        .eq('patient_id', _uid);
    final hiddenIds = (hidden as List).map((h) => h['comment_id']).toSet();

    final comments = await supabase
        .from('comments')
        .select('id, post_id')
        .inFilter('post_id', postIds)
        .eq('is_deleted', false);

    final counts = <String, int>{};
    for (final comment in comments as List) {
      if (hiddenIds.contains(comment['id'])) continue;
      final postId = comment['post_id'] as String;
      counts[postId] = (counts[postId] ?? 0) + 1;
    }

    return counts;
  }

  Future<void> _log(String action, {String? targetId}) async {
    await _activityLogsTable.insert(
      patientId: _uid,
      action: action,
      targetType: 'post',
      targetId: targetId,
    );
  }
}
