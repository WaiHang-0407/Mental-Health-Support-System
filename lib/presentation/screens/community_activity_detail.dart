import 'package:flutter/material.dart';
import '../../controllers/community_activity_controller.dart';
import '../../models/community_activity.dart';
import '../../widgets/gradient_background.dart';

class CommunityActivityDetailPage extends StatelessWidget {
  final CommunityActivity activity;
  final CommunityActivityController controller;
  const CommunityActivityDetailPage({
    super.key,
    required this.activity,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isFull =
        activity.maxParticipants != null &&
        activity.registeredCount >= activity.maxParticipants!;

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
            'Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (activity.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  activity.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(
              activity.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (activity.description != null) ...[
              const SizedBox(height: 10),
              Text(
                activity.description!,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
            const SizedBox(height: 16),
            _infoRow(
              Icons.calendar_today,
              activity.eventDate != null
                  ? _formatDate(activity.eventDate!)
                  : 'TBA',
            ),
            if (activity.location != null)
              _infoRow(Icons.location_on_outlined, activity.location!),
            _infoRow(
              Icons.people_outline,
              '${activity.registeredCount}${activity.maxParticipants != null ? ' / ${activity.maxParticipants}' : ''} registered',
            ),
            const SizedBox(height: 24),
            // Register / Cancel button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFull && !activity.isRegistered
                    ? null
                    : () async {
                        if (activity.isRegistered) {
                          await controller.cancelRegistration(activity);
                        } else {
                          await controller.register(activity);
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: activity.isRegistered
                      ? Colors.redAccent.withOpacity(0.8)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  activity.isRegistered
                      ? 'Cancel Registration'
                      : isFull
                      ? 'Activity Full'
                      : 'Register Now',
                  style: TextStyle(
                    color: activity.isRegistered
                        ? Colors.white
                        : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, color: Colors.white54, size: 16),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    ),
  );

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
