import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/post_controller.dart';
import '../../models/patient.dart';
import '../../models/post.dart';
import '../../repositories/patient_table_repository.dart';
import '../../repositories/profile_table_repository.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/image_viewer.dart';
import 'post_detail.dart';

class PublicProfilePage extends StatefulWidget {
  final String patientId;
  final String fallbackName;

  const PublicProfilePage({
    super.key,
    required this.patientId,
    this.fallbackName = 'Anonymous',
  });

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  final PatientRepository _patientRepo = PatientRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  final PostController _postController = PostController();
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  PatientModel? patient;
  List<Post> posts = [];
  bool isLoading = true;
  bool isFollowing = false;
  bool isFollowSaving = false;
  int followerCount = 0;
  int followingCount = 0;

  bool get _isOwnProfile => widget.patientId == _uid;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final loadedPatient = await _patientRepo.getPatientById(
        widget.patientId,
      );
      final loadedPosts = await _profileRepo.getPublicPostsByPatient(
        widget.patientId,
      );
      final loadedIsFollowing = await _profileRepo.isFollowing(
        widget.patientId,
      );
      final loadedFollowerCount = await _profileRepo.getFollowerCount(
        widget.patientId,
      );
      final loadedFollowingCount = await _profileRepo.getFollowingCount(
        widget.patientId,
      );
      if (!mounted) return;
      setState(() {
        patient = loadedPatient;
        posts = loadedPosts;
        isFollowing = loadedIsFollowing;
        followerCount = loadedFollowerCount;
        followingCount = loadedFollowingCount;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    if (isFollowSaving) return;
    setState(() => isFollowSaving = true);
    try {
      if (isFollowing) {
        await _profileRepo.unfollowPatient(widget.patientId);
        if (!mounted) return;
        setState(() {
          isFollowing = false;
          followerCount = followerCount > 0 ? followerCount - 1 : 0;
        });
      } else {
        await _profileRepo.followPatient(widget.patientId);
        if (!mounted) return;
        setState(() {
          isFollowing = true;
          followerCount += 1;
        });
      }
    } finally {
      if (mounted) setState(() => isFollowSaving = false);
    }
  }

  void _openFollowList({required bool showFollowers}) {
    if (!_isOwnProfile) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FollowListPage(
          patientId: widget.patientId,
          showFollowers: showFollowers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = patient?.name ?? widget.fallbackName;

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
            _isOwnProfile ? 'My Profile' : 'Profile',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.white24,
                        backgroundImage: patient?.avatarUrl != null
                            ? NetworkImage(patient!.avatarUrl!)
                            : null,
                        child: patient?.avatarUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${posts.length} public posts',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _socialCount(
                                  count: followerCount,
                                  label: 'followers',
                                  showFollowers: true,
                                ),
                                const SizedBox(width: 12),
                                _socialCount(
                                  count: followingCount,
                                  label: 'following',
                                  showFollowers: false,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (!_isOwnProfile) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isFollowSaving ? null : _toggleFollow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: isFollowing
                                ? Colors.white70
                                : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  _profileInfoRow(
                    Icons.person_outline,
                    'Gender',
                    patient?.gender,
                  ),
                  _profileInfoRow(
                    Icons.cake_outlined,
                    'Date of birth',
                    _formatDate(patient?.dob),
                  ),
                  _profileInfoRow(
                    Icons.phone_outlined,
                    'Phone',
                    patient?.phoneno,
                  ),
                  _profileInfoRow(
                    Icons.health_and_safety_outlined,
                    'Condition',
                    patient?.condition,
                  ),
                  _profileInfoRow(
                    Icons.pets_outlined,
                    'Favorite companion',
                    patient?.favAnimal,
                  ),
                  _profileInfoRow(
                    Icons.self_improvement_outlined,
                    'Favorite activity',
                    patient?.favActivity,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Public Posts',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Text(
                        'No public posts yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ...posts.map(_postTile),
                ],
              ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialCount({
    required int count,
    required String label,
    required bool showFollowers,
  }) {
    final text = Text(
      '$count $label',
      style: TextStyle(
        color: _isOwnProfile ? Colors.white : Colors.white54,
        fontSize: 12,
        fontWeight: _isOwnProfile ? FontWeight.w700 : FontWeight.w400,
      ),
    );

    if (!_isOwnProfile) return text;

    return InkWell(
      onTap: () => _openFollowList(showFollowers: showFollowers),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: text,
      ),
    );
  }

  String? _formatDate(DateTime? value) {
    if (value == null) return null;
    return '${value.day}/${value.month}/${value.year}';
  }

  Widget _postTile(Post post) {
    final authorName = post.authorName ?? patient?.name ?? widget.fallbackName;

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
                    CircleAvatar(
                      backgroundColor: const Color(0xFF10182E),
                      radius: 21,
                      backgroundImage: post.authorAvatarUrl?.trim().isNotEmpty ==
                              true
                          ? NetworkImage(post.authorAvatarUrl!)
                          : patient?.avatarUrl?.trim().isNotEmpty == true
                          ? NetworkImage(patient!.avatarUrl!)
                          : null,
                      child:
                          post.authorAvatarUrl?.trim().isNotEmpty == true ||
                              patient?.avatarUrl?.trim().isNotEmpty == true
                          ? null
                          : Text(
                              authorName.isNotEmpty
                                  ? authorName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
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
                      onTap: () => _toggleLike(post),
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
                      onPressed: () => _toggleSave(post),
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
        itemBuilder: (_, index) {
          final isLast = index == 4 && imageUrls.length > 5;
          return GestureDetector(
            onTap: () => _openImageViewer(imageUrls, index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(imageUrls[index], fit: BoxFit.cover),
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

  Future<void> _toggleLike(Post post) async {
    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );
    _replacePost(updatedPost);
    await _postController.toggleLike(post);
  }

  Future<void> _toggleSave(Post post) async {
    final updatedPost = post.copyWith(isSaved: !post.isSaved);
    _replacePost(updatedPost);
    await _postController.toggleSave(post);
  }

  void _replacePost(Post updatedPost) {
    setState(() {
      final index = posts.indexWhere((post) => post.id == updatedPost.id);
      if (index != -1) posts[index] = updatedPost;
    });
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
            Icon(icon, size: 19, color: color),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
      ),
      child: const Text(
        'Listener',
        style: TextStyle(
          color: Colors.blueAccent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FollowListPage extends StatefulWidget {
  final String patientId;
  final bool showFollowers;

  const _FollowListPage({
    required this.patientId,
    required this.showFollowers,
  });

  @override
  State<_FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<_FollowListPage> {
  final ProfileRepository _profileRepo = ProfileRepository();

  bool isLoading = true;
  List<PatientModel> patients = [];

  String get _title => widget.showFollowers ? 'Followers' : 'Following';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final loadedPatients = widget.showFollowers
          ? await _profileRepo.getFollowers(widget.patientId)
          : await _profileRepo.getFollowing(widget.patientId);

      if (!mounted) return;
      setState(() {
        patients = loadedPatients;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
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
          title: Text(
            _title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : patients.isEmpty
            ? Center(
                child: Text(
                  widget.showFollowers
                      ? 'No followers yet.'
                      : 'Not following anyone yet.',
                  style: const TextStyle(color: Colors.white60),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadPatients,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  itemCount: patients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _patientTile(patients[index]),
                ),
              ),
      ),
    );
  }

  Widget _patientTile(PatientModel patient) {
    final name = patient.name?.trim().isNotEmpty == true
        ? patient.name!.trim()
        : 'Anonymous';
    final avatarUrl = patient.avatarUrl?.trim();

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PublicProfilePage(
              patientId: patient.id,
              fallbackName: name,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF10182E),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
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
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8A93A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
