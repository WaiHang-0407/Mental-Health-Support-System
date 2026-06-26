import 'package:flutter/material.dart';
import '../presentation/screens/home_patient.dart';
import '../presentation/screens/journal_main.dart';
import '../presentation/screens/chat_main.dart';
import '../presentation/screens/activity_main.dart';
import '../presentation/screens/community.dart';

class MainTabNavigator {
  static final List<Widget> _pages = [
    const HomePatientPage(),
    const JournalMainPage(),
    const ChatMainPage(),
    const ActivityMainPage(),
    const CommunityPage(),
  ];

  static void goTo(BuildContext context, int index, {required int fromIndex}) {
    if (index == fromIndex) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _pages[index],
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const _animationDuration = Duration(milliseconds: 260);
  late int _selectedIndex;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant BottomNavBar oldWidget) {
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

    MainTabNavigator.goTo(context, index, fromIndex: widget.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    const itemCount = 5;
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
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book_outlined),
                    activeIcon: Icon(Icons.book),
                    label: 'Journal',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline),
                    activeIcon: Icon(Icons.chat_bubble),
                    label: 'Chat',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.self_improvement_outlined),
                    activeIcon: Icon(Icons.self_improvement),
                    label: 'Activity',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Community',
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
