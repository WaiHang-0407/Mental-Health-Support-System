import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/activity_path_controller.dart';
import '../../controllers/community_activity_controller.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/post.dart';
import '../../models/user_activity_log.dart';
import '../../repositories/activity_path_repository.dart';
import '../../repositories/community_activity_table_repository.dart';
import '../../widgets/gradient_background.dart';
import 'activity_log_detail.dart';
import 'activity_path_reader.dart';
import 'community_activity_detail.dart';

enum _HistoryFilter {
  all('All'),
  posts('Posts'),
  comments('Comments'),
  activities('Activities'),
  chat('Chat'),
  profile('Profile');

  const _HistoryFilter(this.label);
  final String label;
}

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key});

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  final UserProfileController _controller = UserProfileController();
  final PostController _postController = PostController();
  final CommunityActivityRepository _communityActivityRepo =
      CommunityActivityRepository();
  final ActivityPathRepository _activityPathRepo = ActivityPathRepository();
  final ActivityPathController _activityPathController =
      ActivityPathController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
    _controller.addListener(_refresh);
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    _postController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
                ? _emptyState()
                : _historyContent(),
      ),
    );
  }

  Widget _historyContent() {
    final logs = _filteredLogs();

    return RefreshIndicator(
      onRefresh: _controller.loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _summaryHeader(),
          const SizedBox(height: 14),
          _filterBar(),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            _emptyFilteredState()
          else
            ..._groupedTimeline(logs),
        ],
      ),
    );
  }

  Widget _summaryHeader() {
    final logs = _controller.activityLogs;
    final todayCount = logs
        .where((log) => _activityGroup(log.createdAt) == 'Today')
        .length;
    final weekCount = logs
        .where((log) => DateTime.now().difference(log.createdAt).inDays < 7)
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF9FE7D3).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.history_outlined,
                  color: Color(0xFF9FE7D3),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your app journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Posts, chats, profile updates, and activity actions.',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _summaryMetric('${logs.length}', 'Total'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric('$todayCount', 'Today'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _summaryMetric('$weekCount', '7 days'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryMetric(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _HistoryFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final filter = _HistoryFilter.values[index];
          final selected = filter == _filter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: selected,
            onSelected: (_) => setState(() => _filter = filter),
            showCheckmark: false,
            labelStyle: TextStyle(
              color: const Color(0xFF10182E),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            selectedColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.86),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _groupedTimeline(List<UserActivityLog> logs) {
    final groupedLogs = <String, List<UserActivityLog>>{};
    for (final log in logs) {
      final group = _activityGroup(log.createdAt);
      groupedLogs.putIfAbsent(group, () => []).add(log);
    }

    return groupedLogs.entries.expand((entry) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
          child: Row(
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
        ...entry.value.map(_activityTile),
        const SizedBox(height: 8),
      ];
    }).toList();
  }

  Widget _activityTile(UserActivityLog log) {
    final meta = _metaFor(log);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openActivityLog(log),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(meta.icon, color: meta.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.displayAction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      meta.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        _typePill(meta.label, meta.color),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(log.createdAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_outlined,
                color: Colors.white60,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No activity yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your posts, comments, chats, profile updates, and activity actions will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFilteredState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Icon(Icons.filter_alt_off_outlined, color: Colors.white54),
          const SizedBox(height: 10),
          Text(
            'No ${_filter.label.toLowerCase()} activity found.',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<UserActivityLog> _filteredLogs() {
    if (_filter == _HistoryFilter.all) {
      return _controller.activityLogs;
    }

    return _controller.activityLogs.where((log) {
      return switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.posts => log.action.startsWith('post_'),
        _HistoryFilter.comments => log.action.startsWith('comment_'),
        _HistoryFilter.activities =>
          log.action.startsWith('activity_') || log.targetType == 'activity_path',
        _HistoryFilter.chat => log.action.startsWith('chat_'),
        _HistoryFilter.profile =>
          log.targetType == 'profile' ||
              log.action == 'profile_updated' ||
              log.action == 'personalization_updated' ||
              log.action == 'avatar_updated',
      };
    }).toList();
  }

  _ActivityMeta _metaFor(UserActivityLog log) {
    if (log.action.startsWith('post_')) {
      return const _ActivityMeta(
        icon: Icons.article_outlined,
        color: Color(0xFF9FE7D3),
        label: 'Post',
        subtitle: 'Community post activity',
      );
    }
    if (log.action.startsWith('comment_')) {
      return const _ActivityMeta(
        icon: Icons.mode_comment_outlined,
        color: Color(0xFFB9C7FF),
        label: 'Comment',
        subtitle: 'Comment or reply activity',
      );
    }
    if (log.action.startsWith('activity_') || log.targetType == 'activity_path') {
      return const _ActivityMeta(
        icon: Icons.self_improvement_outlined,
        color: Color(0xFFFFD166),
        label: 'Activity',
        subtitle: 'Activity path or community activity update',
      );
    }
    if (log.action.startsWith('chat_')) {
      return const _ActivityMeta(
        icon: Icons.chat_bubble_outline,
        color: Color(0xFFFFA8D8),
        label: 'Chat',
        subtitle: 'AI companion chat activity',
      );
    }
    if (log.targetType == 'profile' ||
        log.action == 'profile_updated' ||
        log.action == 'personalization_updated' ||
        log.action == 'avatar_updated') {
      return const _ActivityMeta(
        icon: Icons.person_outline,
        color: Color(0xFFA8E6A1),
        label: 'Profile',
        subtitle: 'Profile or preference change',
      );
    }
    return const _ActivityMeta(
      icon: Icons.history_outlined,
      color: Colors.white70,
      label: 'Other',
      subtitle: 'Account activity',
    );
  }

  Future<void> _openActivityLog(UserActivityLog log) async {
    if (await _openCommunityActivityLog(log)) return;
    if (await _openActivityPathLog(log)) return;

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

  Future<bool> _openCommunityActivityLog(UserActivityLog log) async {
    if (log.targetType != 'activity' || log.targetId == null) return false;

    final activity = await _communityActivityRepo.getActivityById(
      log.targetId!,
    );
    if (!mounted) return true;
    if (activity == null) return false;

    final controller = CommunityActivityController();
    controller.activities = [activity];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityActivityDetailPage(
          activity: activity,
          controller: controller,
        ),
      ),
    );
    return true;
  }

  Future<bool> _openActivityPathLog(UserActivityLog log) async {
    if (log.targetType != 'activity_path' || log.targetId == null) {
      return false;
    }

    final path = await _activityPathRepo.getActivePathById(log.targetId!);
    if (!mounted) return true;
    if (path == null) return false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityPathReaderPage(
          path: path,
          onPageProgress: (pageNumber) {
            _activityPathController.updateProgress(
              path: path,
              currentPageNumber: pageNumber,
              completedPageCount: pageNumber - 1,
              isCompleted: false,
            );
          },
          onCompleted: () {
            _activityPathController.updateProgress(
              path: path,
              currentPageNumber: path.pages.length,
              completedPageCount: path.pages.length,
              isCompleted: true,
            );
          },
        ),
      ),
    );
    return true;
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
    if (diff < 7) return 'This Week';
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

class _ActivityMeta {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;

  const _ActivityMeta({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
  });
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
