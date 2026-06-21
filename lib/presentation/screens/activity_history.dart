import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/post.dart';
import '../../models/user_activity_log.dart';
import '../../widgets/gradient_background.dart';
import 'activity_log_detail.dart';

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final UserProfileController _controller = UserProfileController();
  final PostController _postController = PostController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset('assets/images/back.png', height: 24, width: 24),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Activity History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _controller.activityLogs.isEmpty
            ? const Center(
                child: Text(
                  'No activity yet',
                  style: TextStyle(color: Colors.white54),
                ),
              )
            : _activityList(),
      ),
    );
  }

  Widget _activityList() {
    final groupedLogs = <String, List<UserActivityLog>>{};
    for (final log in _controller.activityLogs) {
      final group = _activityGroup(log.createdAt);
      groupedLogs.putIfAbsent(group, () => []).add(log);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: groupedLogs.entries.expand((entry) {
        return [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...entry.value.map(_activityTile),
        ];
      }).toList(),
    );
  }

  Widget _activityTile(UserActivityLog log) {
    return GestureDetector(
      onTap: () => _openActivityLog(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                log.displayAction,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            Text(
              _timeAgo(log.createdAt),
              style: const TextStyle(color: Colors.white30, fontSize: 11),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _openActivityLog(UserActivityLog log) async {
    String? postId = _postIdFromActivity(log);

    if (postId == null && _isCommentActivity(log) && log.targetId != null) {
      postId = await _controller.getPostIdForCommentActivity(log.targetId!);
    }

    Post? post;
    if (postId != null) {
      post = await _controller.getPostByIdForActivity(postId);
    }

    if (!mounted) return;

    final status = _activityStatus(postId, post);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityLogDetailPage(
          log: log,
          post: post,
          statusTitle: status.title,
          statusMessage: status.message,
          canOpenPost: status.canOpenPost,
          postController: _postController,
        ),
      ),
    );
  }

  String? _postIdFromActivity(UserActivityLog log) {
    if (log.targetId == null) return null;
    if (log.targetType == 'post') return log.targetId;
    if (log.action == 'comment_created') return log.targetId;
    return null;
  }

  bool _isCommentActivity(UserActivityLog log) {
    return log.targetType == 'comment' &&
        log.action != 'comment_created' &&
        log.targetId != null;
  }

  _ActivityStatus _activityStatus(String? postId, Post? post) {
    if (postId == null) {
      return const _ActivityStatus(
        title: 'No linked post',
        message:
            'This older activity was saved before the app started tracking related posts.',
        canOpenPost: false,
      );
    }
    if (post == null) {
      return const _ActivityStatus(
        title: 'Post unavailable',
        message:
            'The related post could not be found. It may have been removed.',
        canOpenPost: false,
      );
    }
    if (post.isDeleted) {
      return const _ActivityStatus(
        title: 'Post deleted',
        message: 'The related post was deleted, so it can no longer be opened.',
        canOpenPost: false,
      );
    }
    if (post.isArchived) {
      final isOwn = post.patientId == _uid;
      return _ActivityStatus(
        title: 'Post archived',
        message: isOwn
            ? 'This is your archived post. You can still open it.'
            : 'The author archived this post, so it is no longer visible.',
        canOpenPost: isOwn,
      );
    }
    return const _ActivityStatus(
      title: 'Post available',
      message: 'You can open the related post from here.',
      canOpenPost: true,
    );
  }

  String _activityGroup(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return 'Earlier';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ActivityStatus {
  final String title;
  final String message;
  final bool canOpenPost;

  const _ActivityStatus({
    required this.title,
    required this.message,
    required this.canOpenPost,
  });
}
