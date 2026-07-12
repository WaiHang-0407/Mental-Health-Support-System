import 'package:flutter/material.dart';
import '../presentation/screens/listener_dashboard.dart';
import '../presentation/screens/community.dart';
import '../presentation/screens/profile.dart';

class ListenerBottomNavBar extends StatefulWidget {
  final int currentIndex;

  const ListenerBottomNavBar({super.key, required this.currentIndex});

  @override
  State<ListenerBottomNavBar> createState() => _ListenerBottomNavBarState();
}

class _ListenerBottomNavBarState extends State<ListenerBottomNavBar> {
  static const _animationDuration = Duration(milliseconds: 260);
  late int _selectedIndex;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant ListenerBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _selectedIndex = widget.currentIndex;
    }
  }

  Future<void> _onTap(BuildContext context, int index) async {
    if (index == _selectedIndex || _isNavigating) return;

    setState(() {
      _selectedIndex = index;
      _isNavigating = true;
    });

    await Future.delayed(_animationDuration);
    if (!context.mounted) return;

    Widget page;
    switch (index) {
      case 0:
        page = const ListenerDashboardPage();
        break;
      case 1:
        page = const CommunityPage(useListenerBottomNav: true);
        break;
      case 2:
        page = const ProfilePage(useListenerBottomNav: true);
        break;
      default:
        page = const ListenerDashboardPage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const itemCount = 3;
    const indicatorWidth = 34.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / itemCount;
        final indicatorLeft =
            (itemWidth * _selectedIndex) + ((itemWidth - indicatorWidth) / 2);

        return Container(
          color: const Color(0xFF1A2340),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                left: indicatorLeft,
                top: 0,
                child: Container(
                  width: indicatorWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) => _onTap(context, index),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white54,
                backgroundColor: Colors.transparent,
                elevation: 0,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Community',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
