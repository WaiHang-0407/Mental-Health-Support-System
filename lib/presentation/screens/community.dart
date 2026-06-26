import 'package:flutter/material.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/community_activity_controller.dart';
import '../../models/post.dart';
import '../../models/community_activity.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import 'post_detail.dart';
import 'post_create.dart';
import 'community_activity_detail.dart';
import 'profile.dart';
import 'profile_post_list.dart';
import 'activity_history.dart';
import 'public_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import 'login.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PostController _postController = PostController();
  final CommunityActivityController _activityController =
      CommunityActivityController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
    _postController.loadFeed();
    _postController.addListener(() => setState(() {}));
    _activityController.loadActivities();
    _activityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    _activityController.dispose();
    super.dispose();
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
                      if (reported) {
                        await _askHideReportedPost(post);
                      }
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

  Future<void> _askHideReportedPost(Post post) async {
    final hide = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A2340),
        title: const Text(
          'Hide this post?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You reported this post. Do you also want to hide it from your feed?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hide',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (hide == true) {
      await _postController.hidePost(post);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post hidden from your feed')),
      );
    }
  }

  Widget _buildProfileIcon() {
    // You'll need a patient ref here — simplest is a quick fetch
    // or pass it in. For now use a default person icon with avatar if available.
    return FutureBuilder(
      future: Supabase.instance.client
          .from('patients')
          .select('avatar_url, name')
          .eq('id', Supabase.instance.client.auth.currentUser!.id)
          .maybeSingle(),
      builder: (_, snapshot) {
        final data = snapshot.data;
        final avatarUrl = data?['avatar_url'];
        final name = data?['name'] ?? 'A';
        return CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        );
      },
    );
  }

  void _showProfileMenu() {
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
              leading: const Icon(Icons.person_outline, color: Colors.white70),
              title: const Text(
                'View My Profile',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => _openMenuPage(const ProfilePage()),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white70),
              title: const Text(
                'Activity History',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => _openMenuPage(const ActivityHistoryPage()),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border, color: Colors.white70),
              title: const Text(
                'Saved Posts',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => _openMenuPage(const SavedPostsPage()),
            ),
            ListTile(
              leading: const Icon(
                Icons.archive_outlined,
                color: Colors.white70,
              ),
              title: const Text(
                'Archived Posts',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () => _openMenuPage(const ArchivedPostsPage()),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: _logout,
            ),
          ],
        ),
      ),
    );
  }

  void _openMenuPage(Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _logout() async {
    Navigator.pop(context);
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Community',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: _buildProfileIcon(), // 👈 profile icon top right
              onPressed: _showProfileMenu,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Activities'),
            ],
          ),
        ),
        floatingActionButton: _selectedTabIndex == 0
            ? FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PostCreatePage(controller: _postController),
                    ),
                  );
                },
                child: const Icon(Icons.add, color: Colors.black87),
              )
            : null,
        bottomNavigationBar: const BottomNavBar(currentIndex: 4),
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildFeed(), _buildActivities()],
        ),
      ),
    );
  }

  // In _buildFeed() inside community.dart, replace with:
  Widget _buildFeed() {
    if (_postController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postController.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 40),
            const SizedBox(height: 8),
            const Text(
              'Failed to load posts',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _postController.loadFeed,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_postController.posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet. Be the first!',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _postController.loadFeed,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _postController.posts.length,
        itemBuilder: (_, i) => _buildPostCard(_postController.posts[i]),
      ),
    );
  }

  void _showPostOptions(Post post) {
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
            if (isOwn) ...[
              // Archive toggle
              ListTile(
                leading: Icon(
                  post.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  post.isArchived ? 'Unarchive post' : 'Archive post',
                  style: const TextStyle(color: Colors.white70),
                ),
                subtitle: Text(
                  post.isArchived
                      ? 'Make this post visible again'
                      : 'Hide from feed (only you can see it)',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _postController.toggleArchive(post);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        post.isArchived
                            ? 'Post restored to feed'
                            : 'Post archived',
                      ),
                    ),
                  );
                },
              ),
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
                  _postController.deletePost(post.id);
                },
              ),
            ] else
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

  Widget _buildPostCard(Post post) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PostDetailPage(post: post, postController: _postController),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _openPublicProfile(post),
                    child: CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: 18,
                      child: Text(
                        (post.authorName ?? 'A')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => _openPublicProfile(post),
                          child: Text(
                            post.authorName ?? 'Anonymous',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _timeAgo(post.createdAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Archived badge
                  if (post.isArchived)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Archived',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz, color: Colors.white54),
                    onPressed: () => _showPostOptions(post),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Text(
                post.content,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            // Multiple images
            if (post.imageUrls.isNotEmpty) _buildPostImages(post.imageUrls),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.redAccent : Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => _postController.toggleLike(post),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  Text(
                    '${post.likeCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white54,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: post.isSaved ? Colors.amber : Colors.white54,
                      size: 20,
                    ),
                    onPressed: () => _postController.toggleSave(post),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Multi-image grid with tap to enlarge
  Widget _buildPostImages(List<String> imageUrls) {
    if (imageUrls.length == 1) {
      return GestureDetector(
        onTap: () => _openImageViewer(imageUrls, 0),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          child: Image.network(
            imageUrls[0],
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Grid for 2-5 images
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: imageUrls.length == 2 ? 2 : 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: imageUrls.length == 2 ? 1 : 1,
        ),
        itemCount: imageUrls.length > 5 ? 5 : imageUrls.length,
        itemBuilder: (_, i) {
          final isLast = i == 4 && imageUrls.length > 5;
          return GestureDetector(
            onTap: () => _openImageViewer(imageUrls, i),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrls[i], fit: BoxFit.cover),
                if (isLast)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Text(
                        '+${imageUrls.length - 4}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openImageViewer(List<String> imageUrls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageViewer(imageUrls: imageUrls, initialIndex: index),
      ),
    );
  }

  void _openPublicProfile(Post post) {
    if (post.patientId == _uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfilePage(
          patientId: post.patientId,
          fallbackName: post.authorName ?? 'Anonymous',
        ),
      ),
    );
  }

  Widget _buildActivities() {
    if (_activityController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activityController.activities.isEmpty) {
      return const Center(
        child: Text(
          'No activities yet.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _activityController.activities.length,
      itemBuilder: (_, i) =>
          _buildActivityCard(_activityController.activities[i]),
    );
  }

  Widget _buildActivityCard(CommunityActivity activity) {
    final isFull =
        activity.maxParticipants != null &&
        activity.registeredCount >= activity.maxParticipants!;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityActivityDetailPage(
            activity: activity,
            controller: _activityController,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  activity.imageUrl!,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (activity.eventDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(activity.eventDate!),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (activity.location != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white54,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity.location!,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${activity.registeredCount}${activity.maxParticipants != null ? '/${activity.maxParticipants}' : ''} registered',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activity.isRegistered
                              ? Colors.white.withOpacity(0.15)
                              : isFull
                              ? Colors.white.withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          activity.isRegistered
                              ? 'Registered ✓'
                              : isFull
                              ? 'Full'
                              : 'Register',
                          style: TextStyle(
                            color: activity.isRegistered || isFull
                                ? Colors.white54
                                : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
