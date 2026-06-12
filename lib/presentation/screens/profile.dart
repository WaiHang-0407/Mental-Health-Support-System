// presentation/screens/profile.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_profile_controller.dart';
import '../../controllers/post_controller.dart';
import '../../models/post.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
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
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    await _controller.uploadAvatar(File(picked.path));
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take a photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
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

  void _showPostOptions(Post post, {bool isArchived = false}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
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
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isArchived
                      ? 'Post restored' : 'Post archived'),
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: Colors.redAccent),
              title: const Text('Delete post',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _controller.deletePost(post.id);
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
          title: const Text('My Profile',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
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
                                        (patient?.name ?? 'A')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                              // Upload indicator
                              if (_controller.isUploadingAvatar)
                                Positioned.fill(
                                  child: CircleAvatar(
                                    backgroundColor:
                                        Colors.black.withOpacity(0.5),
                                    child: const SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              // Camera icon badge
                              Positioned(
                                bottom: 0, right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 12, color: Colors.black87),
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
                                    fontWeight: FontWeight.bold),
                              ),
                              if (patient?.condition != null &&
                                  patient!.condition!.isNotEmpty)
                                Text(
                                  patient.condition!
                                      .split(',')
                                      .take(2)
                                      .join(', '),
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 13),
                                ),
                              const SizedBox(height: 6),
                              // Stats row
                              Row(
                                children: [
                                  _statChip('${_controller.myPosts.length}',
                                      'Posts'),
                                  const SizedBox(width: 16),
                                  _statChip(
                                      '${_controller.savedPosts.length}',
                                      'Saved'),
                                  const SizedBox(width: 16),
                                  _statChip(
                                      '${_controller.archivedPosts.length}',
                                      'Archived'),
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
                        _buildPostsTab(_controller.myPosts,
                            emptyMsg: 'No posts yet'),
                        _buildPostsTab(_controller.savedPosts,
                            emptyMsg: 'No saved posts'),
                        _buildPostsTab(_controller.archivedPosts,
                            isArchived: true,
                            emptyMsg: 'No archived posts'),
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
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildPostsTab(List<Post> posts,
      {bool isArchived = false, required String emptyMsg}) {
    if (posts.isEmpty) {
      return Center(
        child: Text(emptyMsg,
            style: const TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: posts.length,
      itemBuilder: (_, i) => _buildMiniPostCard(posts[i],
          isArchived: isArchived),
    );
  }

  Widget _buildMiniPostCard(Post post, {bool isArchived = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => PostDetailPage(
              post: post, postController: _postController))),
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
                    child: Icon(Icons.archive_outlined,
                        color: Colors.white38, size: 14),
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
                  icon: const Icon(Icons.more_horiz,
                      color: Colors.white38, size: 18),
                  onPressed: () =>
                      _showPostOptions(post, isArchived: isArchived),
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
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewer(
                              imageUrls: post.imageUrls,
                              initialIndex: i),
                        )),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(post.imageUrls[i],
                            width: 60, height: 60, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.favorite_border,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text('${post.likeCount}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.chat_bubble_outline,
                    color: Colors.white38, size: 14),
                const SizedBox(width: 4),
                Text('${post.commentCount}',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
                const Spacer(),
                Text(_timeAgo(post.createdAt),
                    style: const TextStyle(
                        color: Colors.white30, fontSize: 11)),
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
        child: Text('No activity yet',
            style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _controller.activityLogs.length,
      itemBuilder: (_, i) {
        final log = _controller.activityLogs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(log.displayAction,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
              ),
              Text(_timeAgo(log.createdAt),
                  style: const TextStyle(
                      color: Colors.white30, fontSize: 11)),
            ],
          ),
        );
      },
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
}