// presentation/screens/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../controllers/user_profile_controller.dart';
import '../../controllers/post_controller.dart';
import '../../models/post.dart';
import '../../models/user_activity_log.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import 'activity_log_detail.dart';
import 'post_detail.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final UserProfileController _controller = UserProfileController();
  final PostController _postController = PostController();
  final ImagePicker _picker = ImagePicker();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller.loadProfile();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    await _controller.uploadAvatar(File(picked.path));
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) {
                  await _controller.uploadAvatar(File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(Post post) async {
    final reasons = [
      'Inappropriate content',
      'Spam',
      'Harassment',
      'Misinformation',
      'Other',
    ];
    String? selected;
    final otherReasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A2340),
          title: const Text(
            'Report Post',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...reasons.map(
                (r) => RadioListTile<String>(
                  value: r,
                  groupValue: selected,
                  onChanged: (v) => setS(() => selected = v),
                  title: Text(
                    r,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  activeColor: Colors.white,
                ),
              ),
              if (selected == 'Other') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: otherReasonController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Type your reason...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white70),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (_) => setS(() {}),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed:
                  selected == null ||
                      (selected == 'Other' &&
                          otherReasonController.text.trim().isEmpty)
                  ? null
                  : () async {
                      final reason = selected == 'Other'
                          ? otherReasonController.text.trim()
                          : selected!;
                      Navigator.pop(context);
                      final reported = await _postController.reportPost(
                        post,
                        reason,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            reported
                                ? 'Report submitted'
                                : 'Unable to submit report',
                          ),
                        ),
                      );
                    },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
      ),
    );
    otherReasonController.dispose();
  }

  void _showPostOptions(
    Post post, {
    bool isArchived = false,
    bool isSaved = false,
  }) {
    final isOwn = post.patientId == _uid;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwn)
              ListTile(
                leading: Icon(
                  isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  isArchived ? 'Unarchive post' : 'Archive post',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _controller.toggleArchive(post);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArchived ? 'Post restored' : 'Post archived',
                      ),
                    ),
                  );
                },
              ),
            if (isOwn && !isSaved)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete post',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _controller.deletePost(post.id);
                },
              ),
            if (!isOwn)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.white70),
                title: const Text(
                  'Report post',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(post);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = _controller.patient;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Profile header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: Colors.white24,
                                backgroundImage: patient?.avatarUrl != null
                                    ? NetworkImage(patient!.avatarUrl!)
                                    : null,
                                child: patient?.avatarUrl == null
                                    ? Text(
                                        (patient?.name ?? 'A')[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              // Upload indicator
                              if (_controller.isUploadingAvatar)
                                Positioned.fill(
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withOpacity(
                                      0.5,
                                    ),
                                    child: const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              // Camera icon badge
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                patient?.name ?? 'Anonymous',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (patient?.condition != null &&
                                  patient!.condition!.isNotEmpty)
                                Text(
                                  patient.condition!
                                      .split(',')
                                      .take(2)
                                      .join(', '),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              const SizedBox(height: 6),
                              // Stats row
                              Row(
                                children: [
                                  _statChip(
                                    '${_controller.myPosts.length}',
                                    'Posts',
                                  ),
                                  const SizedBox(width: 16),
                                  _statChip(
                                    '${_controller.savedPosts.length}',
                                    'Saved',
                                  ),
                                  const SizedBox(width: 16),
                                  _statChip(
                                    '${_controller.archivedPosts.length}',
                                    'Archived',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Saved'),
                      Tab(text: 'Archived'),
                      Tab(text: 'Activity'),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPostsTab(
                          _controller.myPosts,
                          emptyMsg: 'No posts yet',
                        ),
                        _buildPostsTab(
                          _controller.savedPosts,
                          isSaved: true,
                          emptyMsg: 'No saved posts',
                        ),
                        _buildPostsTab(
                          _controller.archivedPosts,
                          isArchived: true,
                          emptyMsg: 'No archived posts',
                        ),
                        _buildActivityTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildPostsTab(
    List<Post> posts, {
    bool isArchived = false,
    bool isSaved = false,
    required String emptyMsg,
  }) {
    if (posts.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (_, i) => _buildMiniPostCard(
        posts[i],
        isArchived: isArchived,
        isSaved: isSaved,
      ),
    );
  }

  Widget _buildMiniPostCard(
    Post post, {
    bool isArchived = false,
    bool isSaved = false,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PostDetailPage(post: post, postController: _postController),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isArchived ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isArchived)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.archive_outlined,
                      color: Colors.white38,
                      size: 14,
                    ),
                  ),
                Expanded(
                  child: Text(
                    post.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isArchived ? Colors.white54 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white38,
                    size: 18,
                  ),
                  onPressed: () => _showPostOptions(
                    post,
                    isArchived: isArchived,
                    isSaved: isSaved,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewer(
                          imageUrls: post.imageUrls,
                          initialIndex: i,
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls[i],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.favorite_border,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likeCount}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white38,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  _timeAgo(post.createdAt),
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_controller.activityLogs.isEmpty) {
      return const Center(
        child: Text('No activity yet', style: TextStyle(color: Colors.white54)),
      );
    }

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
          ...entry.value.map((log) => _buildActivityLogTile(log)),
        ];
      }).toList(),
    );
  }

  Widget _buildActivityLogTile(UserActivityLog log) {
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

    final status = _activityStatus(log, postId, post);
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

  _ActivityStatus _activityStatus(
    UserActivityLog log,
    String? postId,
    Post? post,
  ) {
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
            ? 'This is your archived post. You can still find it in your Archived tab.'
            : 'The author archived this post, so it is no longer visible in the community feed.',
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
