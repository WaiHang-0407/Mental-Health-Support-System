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
  String get _emptyText =>
      _isSaved ? 'No saved posts yet.' : 'No archived posts yet.';

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
            : posts.isEmpty
            ? Center(
                child: Text(
                  _emptyText,
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (_, i) => _postCard(posts[i]),
              ),
      ),
    );
  }

  Widget _postCard(Post post) {
    final isOwn = post.patientId == _uid;
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
          color: Colors.white.withOpacity(_isSaved ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!_isSaved)
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
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz,
                    color: Colors.white38,
                    size: 18,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showOptions(post, isOwn),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(Post post, bool isOwn) {
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
                  Icons.visibility_off,
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
