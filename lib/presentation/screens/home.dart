import 'package:flutter/material.dart';

import '../../models/admin_profile.dart';
import 'admin_activity_logs.dart';
import 'activities.dart';
import 'activity_paths.dart';
import 'affirmations.dart';
import 'community.dart';
import 'daily_activities.dart';
import 'sponsorships.dart';
import 'users.dart';

enum AdminSection {
  home,
  users,
  reports,
  activityPaths,
  community,
  activities,
  sponsorships,
  affirmations,
  dailyActivities,
  activityLogs,
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.adminProfile,
    this.onSignOut,
  });

  final AdminProfile? adminProfile;
  final VoidCallback? onSignOut;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AdminSection _selectedSection = AdminSection.home;

  void _selectSection(AdminSection section) {
    setState(() {
      _selectedSection = section;
    });
  }

  Widget _contentForSection() {
    return switch (_selectedSection) {
      AdminSection.home => const _HomeContent(),
      AdminSection.users => UsersPage(),
      AdminSection.reports => const _ComingSoonContent(
          title: 'Reports',
          subtitle: 'Review reported posts and comments.',
        ),
      AdminSection.activityPaths => ActivityPathsPage(),
      AdminSection.community => CommunityPage(),
      AdminSection.activities => ActivitiesPage(),
      AdminSection.sponsorships => SponsorshipsPage(),
      AdminSection.affirmations => AffirmationsPage(),
      AdminSection.dailyActivities => DailyActivitiesPage(),
      AdminSection.activityLogs => AdminActivityLogsPage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            adminProfile: widget.adminProfile,
            onSignOut: widget.onSignOut,
            selectedSection: _selectedSection,
            onSelectSection: _selectSection,
          ),
          Expanded(child: _contentForSection()),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.adminProfile,
    required this.onSignOut,
    required this.selectedSection,
    required this.onSelectSection,
  });

  final AdminProfile? adminProfile;
  final VoidCallback? onSignOut;
  final AdminSection selectedSection;
  final ValueChanged<AdminSection> onSelectSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Color(0xFF14211D),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BrandMark(),
              SizedBox(width: 12),
              Text(
                'Mindly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: selectedSection == AdminSection.home,
                  onTap: () => onSelectSection(AdminSection.home),
                ),
                _NavItem(
                  icon: Icons.people_alt_outlined,
                  label: 'Users',
                  selected: selectedSection == AdminSection.users,
                  onTap: () => onSelectSection(AdminSection.users),
                ),
                _NavItem(
                  icon: Icons.report_outlined,
                  label: 'Reports',
                  selected: selectedSection == AdminSection.reports,
                  onTap: () => onSelectSection(AdminSection.reports),
                ),
                _NavItem(
                  icon: Icons.route_outlined,
                  label: 'Activity Path',
                  selected: selectedSection == AdminSection.activityPaths,
                  onTap: () => onSelectSection(AdminSection.activityPaths),
                ),
                _NavItem(
                  icon: Icons.forum_outlined,
                  label: 'Community',
                  selected: selectedSection == AdminSection.community,
                  onTap: () => onSelectSection(AdminSection.community),
                ),
                _NavItem(
                  icon: Icons.event_outlined,
                  label: 'Community Activities',
                  selected: selectedSection == AdminSection.activities,
                  onTap: () => onSelectSection(AdminSection.activities),
                ),
                _NavItem(
                  icon: Icons.volunteer_activism_outlined,
                  label: 'Sponsorships',
                  selected: selectedSection == AdminSection.sponsorships,
                  onTap: () => onSelectSection(AdminSection.sponsorships),
                ),
                _NavItem(
                  icon: Icons.format_quote,
                  label: 'Affirmations',
                  selected: selectedSection == AdminSection.affirmations,
                  onTap: () => onSelectSection(AdminSection.affirmations),
                ),
                _NavItem(
                  icon: Icons.self_improvement_outlined,
                  label: 'Daily Activities',
                  selected: selectedSection == AdminSection.dailyActivities,
                  onTap: () => onSelectSection(AdminSection.dailyActivities),
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  label: 'Activity Logs',
                  selected: selectedSection == AdminSection.activityLogs,
                  onTap: () => onSelectSection(AdminSection.activityLogs),
                ),
              ],
            ),
          ),
          SizedBox(height: 14),
          _AdminProfile(adminProfile: adminProfile, onSignOut: onSignOut),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFBFE8D8),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(Icons.psychology_alt_outlined, color: Color(0xFF14211D), size: 24),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Color(0xFF24463D) : Colors.transparent,
        borderRadius: BorderRadius.all(Radius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(Radius.circular(8)),
          child: SizedBox(
            height: 46,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: selected ? Colors.white : Color(0xFF9FB3AD),
                    size: 21,
                  ),
                  SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Color(0xFF9FB3AD),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminProfile extends StatelessWidget {
  const _AdminProfile({
    required this.adminProfile,
    required this.onSignOut,
  });

  final AdminProfile? adminProfile;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final email = adminProfile?.email;

    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFBFE8D8),
          child: Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF14211D), size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                email?.isNotEmpty == true ? email! : 'Web console',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF9FB3AD), fontSize: 12),
              ),
            ],
          ),
        ),
        if (onSignOut != null)
          IconButton(
            onPressed: onSignOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout, color: Color(0xFF9FB3AD), size: 20),
          ),
      ],
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            SizedBox(height: 28),
            _MetricGrid(),
            SizedBox(height: 22),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _ReviewQueue()),
                  SizedBox(width: 22),
                  Expanded(flex: 2, child: _SystemPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComingSoonContent extends StatelessWidget {
  const _ComingSoonContent({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17201D),
              ),
            ),
            SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
            ),
            SizedBox(height: 28),
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Available soon',
                    style: TextStyle(
                      color: Color(0xFF66736F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Home',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17201D),
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Overview for moderation, community activity, and platform operations.',
                style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: null,
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications_outlined),
        ),
        SizedBox(width: 10),
        IconButton.filled(
          onPressed: null,
          tooltip: 'Refresh',
          icon: Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 900 ? 2 : 4;

        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 2 ? 2.2 : 1.65,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _MetricCard(icon: Icons.people_alt_outlined, label: 'Total users', value: '-'),
            _MetricCard(icon: Icons.flag_outlined, label: 'Pending reports', value: '-'),
            _MetricCard(icon: Icons.event_available_outlined, label: 'Activities', value: '-'),
            _MetricCard(icon: Icons.chat_bubble_outline, label: 'Chat sessions', value: '-'),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Color(0xFF1F7A64), size: 25),
            Spacer(),
            Text(
              value,
              style: TextStyle(
                color: Color(0xFF17201D),
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(label, style: TextStyle(color: Color(0xFF66736F))),
          ],
        ),
      ),
    );
  }
}

class _ReviewQueue extends StatelessWidget {
  const _ReviewQueue();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moderation Queue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17201D),
              ),
            ),
            SizedBox(height: 14),
            _QueueRow(icon: Icons.article_outlined, title: 'Reported posts', status: 'Pending review'),
            _QueueRow(icon: Icons.comment_outlined, title: 'Reported comments', status: 'Pending review'),
            _QueueRow(icon: Icons.visibility_off_outlined, title: 'Hidden content', status: 'Ready for audit'),
            _QueueRow(icon: Icons.history_outlined, title: 'User activity logs', status: 'Available soon'),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.icon,
    required this.title,
    required this.status,
  });

  final IconData icon;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE8ECEA))),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF1F7A64), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(status, style: TextStyle(color: Color(0xFF66736F), fontSize: 13)),
        ],
      ),
    );
  }
}

class _SystemPanel extends StatelessWidget {
  const _SystemPanel();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Areas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17201D),
              ),
            ),
            SizedBox(height: 14),
            _AreaChip(label: 'Users'),
            _AreaChip(label: 'Patients'),
            _AreaChip(label: 'Posts and comments'),
            _AreaChip(label: 'Reports'),
            _AreaChip(label: 'Activities'),
            _AreaChip(label: 'Sponsorships'),
            _AreaChip(label: 'Logs'),
          ],
        ),
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFFF0F4F2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF243B34))),
    );
  }
}
