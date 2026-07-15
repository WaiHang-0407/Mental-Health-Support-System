import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/post_controller.dart';
import '../../controllers/user_profile_controller.dart';
import '../../models/post.dart';
import '../../widgets/gradient_background.dart';
import 'post_detail.dart';

enum ProfilePostListType { saved, archived }

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePostListPage(type: ProfilePostListType.saved);
  }
}

class ArchivedPostsPage extends StatelessWidget {
  const ArchivedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePostListPage(type: ProfilePostListType.archived);
  }
}

class ProfilePostListPage extends StatefulWidget {
  final ProfilePostListType type;

  const ProfilePostListPage({super.key, required this.type});

  @override
  State<ProfilePostListPage> createState() => _ProfilePostListPageState();
}

class _ProfilePostListPageState extends State<ProfilePostListPage> {
  final UserProfileController _controller = UserProfileController();
  final PostController _postController = PostController();
  final String _uid = Supabase.instance.client.auth.currentUser!.id;

  bool get _isSaved => widget.type == ProfilePostListType.saved;
  String get _title => _isSaved ? 'Saved Posts' : 'Archived Posts';
  String get _subtitle => _isSaved
      ? 'Posts you kept for later, gathered in one quiet place.'
      : 'Your archived posts stay private until you restore them.';
  String get _emptyTitle =>
      _isSaved ? 'No saved posts yet' : 'No archived posts yet';
  String get _emptyMessage => _isSaved
      ? 'Save useful posts from the community and they will appear here.'
      : 'Archive your own posts when you want them away from your public profile.';
  IconData get _heroIcon =>
      _isSaved ? Icons.bookmark_rounded : Icons.archive_rounded;
  Color get _accent =>
      _isSaved ? const Color(0xFFFFC857) : const Color(0xFF9FE7D3);

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

  Future<void> _refresh() => _controller.loadProfile();

  @override
  Widget build(BuildContext context) {
    final posts = _isSaved ? _controller.savedPosts : _controller.archivedPosts;

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
          title: Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: const Color(0xFF10182E),
                backgroundColor: Colors.white,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  children: [
                    _summaryCard(posts.length),
                    const SizedBox(height: 16),
                    if (posts.isEmpty)
                      _emptyState()
                    else
                      ...posts.map(_postCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _summaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(_heroIcon, color: _accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'post' : 'posts'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.68),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 42),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(_heroIcon, color: _accent, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            _emptyTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(Post post) {
    final isOwn = post.patientId == _uid;
    final images = post.imageUrls.where((url) => url.trim().isNotEmpty).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PostDetailPage(post: post, postController: _postController),
              ),
            );
            if (mounted) await _refresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _postHeader(post, isOwn),
                const SizedBox(height: 14),
                Text(
                  post.content,
                  maxLines: images.isEmpty ? 6 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17213A),
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _imagePreview(images),
                ],
                const SizedBox(height: 14),
                _postFooter(post),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _postHeader(Post post, bool isOwn) {
    final name = post.authorName?.trim().isNotEmpty == true
        ? post.authorName!.trim()
        : isOwn
            ? 'You'
            : 'Community member';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFF10182E),
          child: Text(
            name.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF10182E),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(post.createdAt),
                style: const TextStyle(color: Color(0xFF687089), fontSize: 12),
              ),
            ],
          ),
        ),
        _statusPill(),
        const SizedBox(width: 2),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Color(0xFF687089)),
          onPressed: () => _showOptions(post, isOwn),
        ),
      ],
    );
  }

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_heroIcon, color: const Color(0xFF10182E), size: 14),
          const SizedBox(width: 4),
          Text(
            _isSaved ? 'Saved' : 'Archived',
            style: const TextStyle(
              color: Color(0xFF10182E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePreview(List<String> images) {
    final preview = images.take(3).toList();

    return SizedBox(
      height: 142,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _networkImage(preview.first, large: true),
          ),
          if (preview.length > 1) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _networkImage(preview[1])),
                  if (preview.length > 2) ...[
                    const SizedBox(height: 8),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _networkImage(preview[2]),
                          if (images.length > 3)
                            Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '+${images.length - 3}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _networkImage(String url, {bool large = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(large ? 18 : 16),
      child: Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFFE9EDF5),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: Colors.black38),
        ),
      ),
    );
  }

  Widget _postFooter(Post post) {
    return Row(
      children: [
        _metric(Icons.favorite_border_rounded, '${post.likeCount}'),
        const SizedBox(width: 14),
        _metric(Icons.chat_bubble_outline_rounded, '${post.commentCount}'),
        const Spacer(),
        const Text(
          'View details',
          style: TextStyle(
            color: Color(0xFF10182E),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF10182E),
          size: 12,
        ),
      ],
    );
  }

  Widget _metric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF687089), size: 17),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF687089),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = date.day.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}';
  }

  void _showOptions(Post post, bool isOwn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isOwn)
              ListTile(
                leading: Icon(
                  _isSaved ? Icons.archive_outlined : Icons.unarchive_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  _isSaved ? 'Archive post' : 'Unarchive post',
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _controller.toggleArchive(post);
                },
              ),
            if (isOwn && !_isSaved)
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
            if (!isOwn && _isSaved)
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Hide from saved posts',
                  style: TextStyle(color: Colors.white70),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _postController.hidePost(post);
                  _controller.savedPosts.removeWhere((p) => p.id == post.id);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ),
    );
  }
}
