import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/gradient_background.dart';
import '../../repositories/user_role_repository.dart';
import 'listener_dashboard.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileController _controller = UserProfileController();
  final ImagePicker _picker = ImagePicker();
  final UserRoleRepository _roleRepo = UserRoleRepository();

  String? _role;
  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
    _loadRole();
    _controller.addListener(() => setState(() {}));
  }

  Future<void> _loadRole() async {
    final role = await _roleRepo.getCurrentUserRole();

    if (!mounted) return;

    setState(() {
      _role = role;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
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
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white70),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: Colors.white70),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAvatar(ImageSource.camera);
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
    final name = patient?.name ?? 'Anonymous';

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
            'Community Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: _controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: Colors.white24,
                              backgroundImage: patient?.avatarUrl != null
                                  ? NetworkImage(patient!.avatarUrl!)
                                  : null,
                              child: patient?.avatarUrl == null
                                  ? Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            if (_controller.isUploadingAvatar)
                              Positioned.fill(
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(
                                    0.5,
                                  ),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _statChip(
                                  '${_controller.myPosts.length}',
                                  'Posts',
                                ),
                                const SizedBox(width: 18),
                                _statChip(
                                  '${_controller.savedPosts.length}',
                                  'Saved',
                                ),
                                const SizedBox(width: 18),
                                _statChip(
                                  '${_controller.archivedPosts.length}',
                                  'Archived',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _statChip(
                                  '${_controller.followerCount}',
                                  'Followers',
                                ),
                                const SizedBox(width: 18),
                                _statChip(
                                  '${_controller.followingCount}',
                                  'Following',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _sectionTitle('Profile Information'),
                  _infoTile(Icons.person_outline, 'Gender', patient?.gender),
                  _infoTile(
                    Icons.cake_outlined,
                    'Date of birth',
                    patient?.dob == null
                        ? null
                        : '${patient!.dob!.day}/${patient.dob!.month}/${patient.dob!.year}',
                  ),
                  _infoTile(Icons.phone_outlined, 'Phone', patient?.phoneno),
                  const SizedBox(height: 18),

                  _sectionTitle('Preferences'),

                  _infoTile(
                    Icons.health_and_safety_outlined,
                    'Condition',
                    patient?.condition,
                  ),

                  _infoTile(
                    Icons.pets_outlined,
                    'Favorite companion',
                    patient?.favAnimal,
                  ),

                  _infoTile(
                    Icons.self_improvement_outlined,
                    'Favorite activity',
                    patient?.favActivity,
                  ),

                  const SizedBox(height: 18),

                  // NEW
                  if (_role == 'listener' || _role == 'patient_listener')
                    _profileAction(
                      Icons.headset_mic_outlined,
                      'Switch to Listener Mode',
                      'Open your listener dashboard.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListenerDashboardPage(),
                          ),
                        );
                      },
                    ),

                  _profileAction(
                    Icons.edit_outlined,
                    'Edit Profile',
                    'Update your name, gender, date of birth, and phone.',
                  ),

                  _profileAction(
                    Icons.tune_outlined,
                    'Edit Preferences',
                    'Update your condition, companion, and activity choices.',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null || value.trim().isEmpty ? 'Not set' : value,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAction(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white38,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
