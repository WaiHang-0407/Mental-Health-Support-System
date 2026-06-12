import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/user_activity_log.dart';

class ProfileRepository {
  final supabase = Supabase.instance.client;
  String get _uid => supabase.auth.currentUser!.id;

  Future<List<Post>> getMyPosts() async {
    final data = await supabase
        .from('posts')
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count)',
        )
        .eq('patient_id', _uid)
        .eq('is_deleted', false)
        .eq('is_archived', false) // public posts only
        .order('created_at', ascending: false);

    return _mapPosts(data as List);
  }

  Future<List<Post>> getMyArchivedPosts() async {
    final data = await supabase
        .from('posts')
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count)',
        )
        .eq('patient_id', _uid)
        .eq('is_deleted', false)
        .eq('is_archived', true) // archived only
        .order('created_at', ascending: false);

    return _mapPosts(data as List);
  }

  Future<List<Post>> getMySavedPosts() async {
    final savedData = await supabase
        .from('saved_posts')
        .select('post_id')
        .eq('patient_id', _uid);

    if ((savedData as List).isEmpty) return [];

    final postIds = savedData.map((s) => s['post_id']).toList();
    final data = await supabase
        .from('posts')
        .select(
          'id, patient_id, content, image_urls, is_deleted, is_archived, created_at, post_likes(count), comments(count)',
        )
        .inFilter('id', postIds)
        .eq('is_deleted', false)
        .order('created_at', ascending: false);

    return _mapPosts(data as List, isSaved: true);
  }

  Future<List<UserActivityLog>> getMyActivityLogs() async {
    final data = await supabase
        .from('user_activity_logs')
        .select()
        .eq('patient_id', _uid)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List).map((e) => UserActivityLog.fromMap(e)).toList();
  }

  List<Post> _mapPosts(
    List data, {
    bool isLiked = false,
    bool isSaved = false,
  }) {
    if (data.isEmpty) return [];
    return data.map((p) {
      final map = <String, dynamic>{
        // 👈 explicitly type the map
        ...Map<String, dynamic>.from(p), // 👈 cast p to Map<String, dynamic>
        'author_name': 'You',
        'like_count': (p['post_likes'] as List?)?.first?['count'] ?? 0,
        'comment_count': (p['comments'] as List?)?.first?['count'] ?? 0,
      };
      return Post.fromMap(map, isLiked: isLiked, isSaved: isSaved);
    }).toList();
  }
}
