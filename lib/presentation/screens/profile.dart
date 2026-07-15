import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_profile_controller.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/listener_bottom_nav_bar.dart';
import '../../repositories/user_role_repository.dart';
import 'listener_dashboard.dart';
import 'profile_post_list.dart';

class ProfilePage extends StatefulWidget {
  final bool useListenerBottomNav;

  const ProfilePage({super.key, this.useListenerBottomNav = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserProfileController _controller = UserProfileController();
  final ImagePicker _picker = ImagePicker();
  final UserRoleRepository _roleRepo = UserRoleRepository();

  String? _role;
  static const _genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];
  static const _conditionOptions = [
    'Depression',
    'Stress',
    'Anxiety',
    'Confidence',
    'Relationships',
    'Trauma',
  ];
  static const _animalOptions = [
    'Dog',
    'Cat',
    'Rabbit',
    'Duck',
    'Parrot',
    'Guinea Pig',
  ];
  static const _activityOptions = [
    'Reading',
    'Music',
    'Exercise',
    'Gaming',
    'Cooking',
    'Art',
  ];
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
          automaticallyImplyLeading: !widget.useListenerBottomNav,
          leading: widget.useListenerBottomNav
              ? null
              : IconButton(
                  icon: Image.asset(
                    'assets/images/back.png',
                    height: 24,
                    width: 24,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
          title: const Text(
            'Community Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        bottomNavigationBar: widget.useListenerBottomNav
            ? const ListenerBottomNavBar(currentIndex: 2)
            : null,
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
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.5,
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
                                  onTap: () => _openProfilePostList(
                                    const SavedPostsPage(),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                _statChip(
                                  '${_controller.archivedPosts.length}',
                                  'Archived',
                                  onTap: () => _openProfilePostList(
                                    const ArchivedPostsPage(),
                                  ),
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
                  _sectionHeader(
                    'Profile Information',
                    onEdit: _showProfileInfoEditor,
                  ),
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

                  _sectionHeader('Preferences', onEdit: _showPreferencesEditor),

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

                  if (widget.useListenerBottomNav)
                    _profileAction(
                      Icons.swap_horiz_outlined,
                      'Switch to Patient',
                      'Return to your patient view.',
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                    )
                  else if (_role == 'listener' || _role == 'patient_listener')
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
                ],
              ),
      ),
    );
  }

  void _openProfilePostList(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) _controller.loadProfile();
    });
  }

  Widget _statChip(String value, String label, {VoidCallback? onTap}) {
    final content = Column(
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

    if (onTap == null) return content;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: content,
      ),
    );
  }

  Widget _sectionHeader(String text, {required VoidCallback onEdit}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF9FE7D3),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

  Future<void> _showProfileInfoEditor() async {
    final patient = _controller.patient;
    String gender = _genderOptions.contains(patient?.gender)
        ? patient!.gender!
        : _genderOptions.first;
    DateTime? dob = patient?.dob;
    final phoneController = TextEditingController(text: patient?.phoneno ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111A33),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              title: const Text(
                'Edit profile information',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    dropdownColor: const Color(0xFF1A2340),
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Gender'),
                    items: [
                      for (final option in _genderOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => gender = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: dob ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => dob = picked);
                      }
                    },
                    icon: const Icon(Icons.cake_outlined),
                    label: Text(
                      dob == null
                          ? 'Select date of birth'
                          : '${dob!.day}/${dob!.month}/${dob!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInputDecoration('Phone number'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _controller.updateProfileFields({
        'gender': gender,
        if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
        'phoneno': phoneController.text.trim(),
      });
      if (mounted) _showSnack('Profile information updated.');
    }
  }

  Future<void> _showPreferencesEditor() async {
    final patient = _controller.patient;
    final selectedConditions = (patient?.condition ?? '')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
    final currentAnimalLabel = _labelFromStoredValue(patient?.favAnimal);
    final currentActivityLabel = _labelFromStoredValue(patient?.favActivity);
    String favAnimal = _animalOptions.contains(currentAnimalLabel)
        ? currentAnimalLabel
        : _animalOptions.first;
    String favActivity = _activityOptions.contains(currentActivityLabel)
        ? currentActivityLabel
        : _activityOptions.first;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111A33),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              title: const Text(
                'Edit preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Condition',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final condition in _conditionOptions)
                          FilterChip(
                            label: Text(condition),
                            selected: selectedConditions.contains(condition),
                            onSelected: (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedConditions.add(condition);
                                } else {
                                  selectedConditions.remove(condition);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: favAnimal,
                      dropdownColor: const Color(0xFF1A2340),
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Favorite companion'),
                      items: [
                        for (final option in _animalOptions)
                          DropdownMenuItem(value: option, child: Text(option)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => favAnimal = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: favActivity,
                      dropdownColor: const Color(0xFF1A2340),
                      style: const TextStyle(color: Colors.white),
                      decoration: _dialogInputDecoration('Favorite activity'),
                      items: [
                        for (final option in _activityOptions)
                          DropdownMenuItem(value: option, child: Text(option)),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => favActivity = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      await _controller.updateProfileFields({
        'condition': selectedConditions.join(','),
        'fav_animal': _animalKey(favAnimal),
        'fav_activity': favActivity.toLowerCase(),
      });
      if (mounted) _showSnack('Preferences updated.');
    }
  }

  String _animalKey(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '-');
  }

  String _labelFromStoredValue(String? value) {
    final normalized = (value ?? '').trim().toLowerCase().replaceAll('-', ' ');
    if (normalized.isEmpty) return '';
    return normalized
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.68)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9FE7D3)),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
