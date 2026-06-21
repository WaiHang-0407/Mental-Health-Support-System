import 'package:flutter/material.dart';
import '../../controllers/post_controller.dart';
import '../../models/patient.dart';
import '../../models/post.dart';
import '../../repositories/patient_table_repository.dart';
import '../../repositories/profile_table_repository.dart';
import '../../widgets/gradient_background.dart';
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

  PatientModel? patient;
  List<Post> posts = [];
  bool isLoading = true;
  bool isFollowing = false;
  bool isFollowSaving = false;
  int followerCount = 0;
  int followingCount = 0;

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
      final loadedPatient = await _patientRepo.getPublicPatientById(
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
          title: const Text(
            'Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                                Text(
                                  '$followerCount followers',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '$followingCount following',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFollowSaving ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Following' : 'Follow',
                        style: TextStyle(
                          color: isFollowing ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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

  Widget _postTile(Post post) {
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
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
}
