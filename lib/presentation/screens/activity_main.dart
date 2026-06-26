import 'package:flutter/material.dart';
import '../../controllers/community_activity_controller.dart';
import '../../models/community_activity.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/auth_service.dart';
import 'community_activity_detail.dart';
import 'login.dart';

class ActivityMainPage extends StatefulWidget {
  const ActivityMainPage({super.key});

  @override
  State<ActivityMainPage> createState() => _ActivityMainPageState();
}

class _ActivityMainPageState extends State<ActivityMainPage> {
  final CommunityActivityController _activityController =
      CommunityActivityController();

  @override
  void initState() {
    super.initState();
    _activityController.addListener(_refresh);
    _activityController.loadActivities();
  }

  @override
  void dispose() {
    _activityController.removeListener(_refresh);
    _activityController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await authService.signOut();

                if (!context.mounted) return;

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 3),
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
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

    return RefreshIndicator(
      onRefresh: _activityController.loadActivities,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _activityController.activities.length,
        itemBuilder: (_, index) =>
            _buildActivityCard(_activityController.activities[index]),
      ),
    );
  }

  Widget _buildActivityCard(CommunityActivity activity) {
    final isFull =
        activity.maxParticipants != null &&
        activity.registeredCount >= activity.maxParticipants!;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
                    _metaRow(
                      Icons.calendar_today,
                      _formatDate(activity.eventDate!),
                    ),
                  ],
                  if (activity.location != null) ...[
                    const SizedBox(height: 2),
                    _metaRow(Icons.location_on_outlined, activity.location!),
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
                              ? 'Registered'
                              : isFull
                              ? 'Full'
                              : 'View Details',
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

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
