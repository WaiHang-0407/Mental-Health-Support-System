import 'package:flutter/material.dart';
import '../../controllers/post_controller.dart';
import '../../controllers/community_activity_controller.dart';
import '../../models/post.dart';
import '../../models/community_activity.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import '../../widgets/listener_bottom_nav_bar.dart';
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
import '../../repositories/user_role_repository.dart';
import 'listener_dashboard.dart';

class CommunityPage extends StatefulWidget {
  final bool useListenerBottomNav;

  const CommunityPage({super.key, this.useListenerBottomNav = false});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TabController _activityTabController;
  final PostController _postController = PostController();
  final CommunityActivityController _activityController =
      CommunityActivityController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;
  final UserRoleRepository _roleRepo = UserRoleRepository();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _activityTabController = TabController(length: 2, vsync: this);
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
    _activityTabController.dispose();
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
              ...reasons.map((r) {
                final isSelected = selected == r;
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setS(() => selected = r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected ? Colors.white : Colors.white54,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            r,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
      builder: (_) => FutureBuilder<String?>(
        future: _roleRepo.getCurrentUserRole(),
        builder: (context, snapshot) {
          final role = snapshot.data;
          final canUseListenerMode =
              role == 'listener' || role == 'patient_listener';

          return SafeArea(
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

                if (canUseListenerMode)
                  ListTile(
                    leading: const Icon(
                      Icons.headset_mic_outlined,
                      color: Colors.lightBlueAccent,
                    ),
                    title: const Text(
                      'Switch to Listener Mode',
                      style: TextStyle(color: Colors.lightBlueAccent),
                    ),
                    onTap: () => _openMenuPage(const ListenerDashboardPage()),
                  ),

                ListTile(
                  leading: const Icon(
                    Icons.person_outline,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'View My Profile',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () => _openMenuPage(
                    ProfilePage(useListenerBottomNav: widget.useListenerBottomNav),
                  ),
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
                  leading: const Icon(
                    Icons.bookmark_border,
                    color: Colors.white70,
                  ),
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
          );
        },
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
      child: MainTabSwipeWrapper(
        currentIndex: 4,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Community',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
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
          bottomNavigationBar: widget.useListenerBottomNav
              ? const ListenerBottomNavBar(currentIndex: 1)
              : const BottomNavBar(currentIndex: 4),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [_buildFeed(), _buildActivities()],
          ),
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
      return RefreshIndicator(
        onRefresh: _postController.loadFeed,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
          children: [
            _emptyCommunityState(
              icon: Icons.forum_outlined,
              title: 'No posts yet',
              message: 'Share the first thought with the community.',
            ),
          ],
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
    final authorName = post.authorName ?? 'Anonymous';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailPage(post: post, postController: _postController),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _openPublicProfile(post),
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFF10182E),
                        radius: 21,
                        backgroundImage:
                            post.authorAvatarUrl?.trim().isNotEmpty == true
                            ? NetworkImage(post.authorAvatarUrl!)
                            : null,
                        child: post.authorAvatarUrl?.trim().isNotEmpty == true
                            ? null
                            : Text(
                                authorName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openPublicProfile(post),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF10182E),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (_isListenerAuthor(post)) ...[
                                  const SizedBox(width: 8),
                                  _listenerBadge(),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _timeAgo(post.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF6C7488),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (post.isArchived)
                      _softPill(
                        'Archived',
                        background: const Color(0xFFE9EDF5),
                        foreground: const Color(0xFF647089),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Color(0xFF647089),
                      ),
                      onPressed: () => _showPostOptions(post),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  post.content,
                  style: const TextStyle(
                    color: Color(0xFF17213A),
                    fontSize: 15,
                    height: 1.42,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildPostImages(post.imageUrls),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _postAction(
                      icon: post.isLiked
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      label: '${post.likeCount}',
                      color: post.isLiked
                          ? Colors.redAccent
                          : const Color(0xFF647089),
                      onTap: () => _postController.toggleLike(post),
                    ),
                    const SizedBox(width: 14),
                    _postAction(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${post.commentCount}',
                      color: const Color(0xFF647089),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(
                            post: post,
                            postController: _postController,
                            focusCommentOnOpen: true,
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        post.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: post.isSaved
                            ? const Color(0xFFFFB020)
                            : const Color(0xFF647089),
                      ),
                      onPressed: () => _postController.toggleSave(post),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          borderRadius: BorderRadius.circular(18),
          child: Image.network(
            imageUrls[0],
            width: double.infinity,
            height: 210,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Grid for 2-5 images
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
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

  Widget _emptyCommunityState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 44),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _postAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isListenerAuthor(Post post) {
    return post.authorRole == 'listener' ||
        post.authorRole == 'patient_listener';
  }

  Widget _listenerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF9CC7FF)),
      ),
      child: const Text(
        'Listener',
        style: TextStyle(
          color: Color(0xFF2463A7),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _softPill(
    String text, {
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _eventMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF647089), size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF647089),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivities() {
    if (_activityController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activityController.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 42),
              const SizedBox(height: 12),
              Text(
                _activityController.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _activityController.loadActivities,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_activityController.activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _activityController.loadActivities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 80, 16, 80),
          children: [
            _emptyCommunityState(
              icon: Icons.event_available_outlined,
              title: 'No activities yet',
              message: 'Community activities will appear here.',
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: _activityFilter(),
        ),
        Expanded(
          child: TabBarView(
            controller: _activityTabController,
            physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
            children: [
              _buildActivityFilterPage(completed: false),
              _buildActivityFilterPage(completed: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityFilterPage({required bool completed}) {
    final filteredActivities = _filteredCommunityActivities(completed);

    if (filteredActivities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _activityController.loadActivities,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
          children: [
            _emptyCommunityState(
              icon: completed
                  ? Icons.history_outlined
                  : Icons.event_available_outlined,
              title: completed
                  ? 'No completed activities'
                  : 'No upcoming activities',
              message: completed
                  ? 'Completed community activities will appear here.'
                  : 'Upcoming activities will appear here when available.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _activityController.loadActivities,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 80),
        itemCount: filteredActivities.length,
        itemBuilder: (_, i) => _buildActivityCardV2(filteredActivities[i]),
      ),
    );
  }

  List<CommunityActivity> _filteredCommunityActivities(bool completed) {
    return _activityController.activities.where((activity) {
      final isCompleted = _isCompletedActivity(activity);
      return completed ? isCompleted : !isCompleted;
    }).toList();
  }

  Widget _activityFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: _activityTabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: const Color(0xFF10182E),
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available_outlined, size: 16),
                SizedBox(width: 6),
                Text('Upcoming'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_outlined, size: 16),
                SizedBox(width: 6),
                Text('Completed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCardV2(CommunityActivity activity) {
    final imageUrl = activity.imageUrl?.trim();
    final location = activity.location?.trim();
    final isCompleted = _isCompletedActivity(activity);
    final isFull =
        activity.maxParticipants != null &&
        activity.registeredCount >= activity.maxParticipants!;
    final statusLabel = isCompleted
        ? 'Completed'
        : activity.isRegistered
        ? 'Registered'
        : isFull
        ? 'Full'
        : 'Open';
    final statusColor = isCompleted
        ? const Color(0xFFE9EDF5)
        : activity.isRegistered
        ? const Color(0xFF9FE7D3)
        : isFull
        ? const Color(0xFFE9EDF5)
        : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityActivityDetailPage(
                activity: activity,
                controller: _activityController,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 170,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        height: 126,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF9FE7D3), Color(0xFFB9C7FF)],
                          ),
                        ),
                        child: const Icon(
                          Icons.event_available_outlined,
                          color: Color(0xFF10182E),
                          size: 44,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _softPill(
                          statusLabel,
                          background: statusColor,
                          foreground: const Color(0xFF10182E),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFF647089),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activity.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF10182E),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        height: 1.18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (activity.eventDate != null)
                      _eventMeta(
                        Icons.calendar_today_outlined,
                        _formatDate(activity.eventDate!),
                      ),
                    if (location != null && location.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      _eventMeta(Icons.location_on_outlined, location),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _eventMeta(
                            Icons.group_outlined,
                            '${activity.registeredCount}${activity.maxParticipants != null ? '/${activity.maxParticipants}' : ''} registered',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'View details',
                          style: TextStyle(
                            color: Color(0xFF10182E),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
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
      ),
    );
  }

  bool _isCompletedActivity(CommunityActivity activity) {
    final eventDate = activity.eventDate;
    if (eventDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
    ).isBefore(today);
  }

  Widget buildActivityCardLegacy(CommunityActivity activity) {
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
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                              ? Colors.white.withValues(alpha: 0.15)
                              : isFull
                              ? Colors.white.withValues(alpha: 0.05)
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
