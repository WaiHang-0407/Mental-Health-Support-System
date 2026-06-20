// repositories/post_repository.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';

class PostRepository {
  final supabase = Supabase.instance.client;
  String get _uid => supabase.auth.currentUser!.id;

  Future<List<Post>> getFeed({int page = 0, int limit = 20}) async {
    final from = page * limit;
    final data = await supabase
        .from('posts')
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count)',
        )
        .eq('is_deleted', false)
        .eq('is_archived', false) // 👈 hide archived from feed
        .order('created_at', ascending: false)
        .range(from, from + limit - 1);

    if ((data as List).isEmpty) return [];

    final patientIds = data.map((p) => p['patient_id']).toList();
    final patientData = await supabase
        .from('patients')
        .select('id, name')
        .inFilter('id', patientIds);
    final nameMap = {for (final p in patientData as List) p['id']: p['name']};

    final postIds = data.map((p) => p['id']).toList();
    final likes = await supabase
        .from('post_likes')
        .select('post_id')
        .eq('patient_id', _uid)
        .inFilter('post_id', postIds);
    final saves = await supabase
        .from('saved_posts')
        .select('post_id')
        .eq('patient_id', _uid)
        .inFilter('post_id', postIds);

    final likedIds = (likes as List).map((l) => l['post_id']).toSet();
    final savedIds = (saves as List).map((s) => s['post_id']).toSet();

    return data.map((p) {
      // Any place you do {...p, 'author_name': ...} — change to:
      final map = <String, dynamic>{
        ...Map<String, dynamic>.from(p),
        'author_name': nameMap[p['patient_id']] ?? 'Anonymous',
        'like_count': (p['post_likes'] as List?)?.first?['count'] ?? 0,
        'comment_count': (p['comments'] as List?)?.first?['count'] ?? 0,
      };
      return Post.fromMap(
        map,
        isLiked: likedIds.contains(p['id']),
        isSaved: savedIds.contains(p['id']),
      );
    }).toList();
  }

  // Get only current user's posts including archived (for their profile)
  Future<List<Post>> getMyPosts() async {
    final data = await supabase
        .from('posts')
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count)',
        )
        .eq('patient_id', _uid)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    if ((data as List).isEmpty) return [];

    final patientData = await supabase
        .from('patients')
        .select('id, name')
        .eq('id', _uid)
        .maybeSingle();

    final name = patientData?['name'] ?? 'Anonymous';

    return data.map((p) {
      final map = {
        ...p,
        'author_name': name,
        'like_count': (p['post_likes'] as List?)?.first?['count'] ?? 0,
        'comment_count': (p['comments'] as List?)?.first?['count'] ?? 0,
      };
      return Post.fromMap(map);
    }).toList();
  }

  Future<void> createPost(
    String content, {
    List<String> imageUrls = const [],
  }) async {
    final data = await supabase
        .from('posts')
        .insert({
          'patient_id': _uid,
          'content': content,
          'image_urls': imageUrls.join(','), // store as comma-separated
        })
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

  // 👇 Toggle archive
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
      await supabase
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('patient_id', _uid);
    } else {
      await supabase.from('post_likes').insert({
        'post_id': postId,
        'patient_id': _uid,
      });
      await _log('post_liked', targetId: postId);
    }
  }

  Future<void> toggleSave(String postId, bool isSaved) async {
    if (isSaved) {
      await supabase
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('patient_id', _uid);
      await _log('post_unsaved', targetId: postId);
    } else {
      await supabase.from('saved_posts').insert({
        'post_id': postId,
        'patient_id': _uid,
      });
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

    await supabase.from('reports').insert({
      'reporter_id': _uid,
      'post_id': postId,
      'reason': reason,
    });
    await _log('post_reported', targetId: postId);
  }

  // Upload multiple images
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

  Future<void> _log(String action, {String? targetId}) async {
    await supabase.from('user_activity_logs').insert({
      'patient_id': _uid,
      'action': action,
      'target_type': 'post',
      if (targetId != null) 'target_id': targetId,
    });
  }
}
