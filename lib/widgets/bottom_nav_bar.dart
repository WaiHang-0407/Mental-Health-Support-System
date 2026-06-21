import 'package:flutter/material.dart';
import '../presentation/screens/home_patient.dart';
import '../presentation/screens/journal_main.dart';
import '../presentation/screens/chat_main.dart';
import '../presentation/screens/activity_main.dart';
import '../presentation/screens/community.dart';

class MainTabSwipeArea extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const MainTabSwipeArea({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  static const _pageCount = 5;
  static const _minSwipeVelocity = 420.0;

  void _handleSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < _minSwipeVelocity) return;

    final targetIndex = velocity < 0 ? currentIndex + 1 : currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= _pageCount) return;

    MainTabNavigator.goTo(context, targetIndex, fromIndex: currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) => _handleSwipe(context, details),
      child: child,
    );
  }
}

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

    final beginOffset = index > fromIndex
        ? const Offset(1, 0)
        : const Offset(-1, 0);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _pages[index],
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
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
