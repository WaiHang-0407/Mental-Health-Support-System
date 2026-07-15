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

  static void goTo(
    BuildContext context,
    int index, {
    required int fromIndex,
    bool animated = false,
  }) {
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

class MainTabPreviewScope extends InheritedWidget {
  final bool hideBottomNav;

  const MainTabPreviewScope({
    super.key,
    required this.hideBottomNav,
    required super.child,
  });

  static bool shouldHideBottomNav(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<MainTabPreviewScope>()
            ?.hideBottomNav ??
        false;
  }

  @override
  bool updateShouldNotify(MainTabPreviewScope oldWidget) {
    return hideBottomNav != oldWidget.hideBottomNav;
  }
}

class MainTabSwipeWrapper extends StatefulWidget {
  final int currentIndex;
  final Widget child;
  final bool enabled;

  const MainTabSwipeWrapper({
    super.key,
    required this.currentIndex,
    required this.child,
    this.enabled = true,
  });

  @override
  State<MainTabSwipeWrapper> createState() => _MainTabSwipeWrapperState();
}

class _MainTabSwipeWrapperState extends State<MainTabSwipeWrapper> {
  double _dragDistance = 0;
  double _dragProgress = 0;
  int? _previewIndex;

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragDistance = 0;
      _dragProgress = 0;
      _previewIndex = null;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0;
    _updatePreview();
  }

  void _updatePreview() {
    final targetIndex = _targetIndexForDistance(_dragDistance);
    setState(() {
      _previewIndex = targetIndex;
      _dragProgress = targetIndex == null
          ? 0
          : (_dragDistance.abs() / 130).clamp(0.0, 1.0).toDouble();
    });
  }

  int? _targetIndexForDistance(double distance) {
    if (distance.abs() < 8) return null;
    final targetIndex = distance < 0
        ? widget.currentIndex + 1
        : widget.currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= MainTabNavigator._pages.length) {
      return null;
    }
    return targetIndex;
  }

  void _handleSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final hasFastSwipe = velocity.abs() >= 280;
    final hasLongSwipe = _dragDistance.abs() >= 72;

    if (!hasFastSwipe && !hasLongSwipe) {
      _resetPreview();
      return;
    }

    final direction = hasFastSwipe ? velocity : _dragDistance;
    final nextIndex = direction < 0
        ? widget.currentIndex + 1
        : widget.currentIndex - 1;
    if (nextIndex < 0 || nextIndex >= MainTabNavigator._pages.length) {
      _resetPreview();
      return;
    }

    MainTabNavigator.goTo(
      context,
      nextIndex,
      fromIndex: widget.currentIndex,
      animated: true,
    );
    _resetPreview();
  }

  void _handleDragCancel() {
    _resetPreview();
  }

  void _resetPreview() {
    if (!mounted) return;
    setState(() {
      _dragDistance = 0;
      _dragProgress = 0;
      _previewIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: (details) => _handleSwipe(context, details),
      onHorizontalDragCancel: _handleDragCancel,
      child: MainTabSwipePreview(
        currentIndex: widget.currentIndex,
        previewIndex: _previewIndex,
        progress: _dragProgress,
        dragDistance: _dragDistance,
        child: widget.child,
      ),
    );
  }
}

class MainTabEdgeSwipeZones extends StatefulWidget {
  final int currentIndex;
  final Widget child;

  const MainTabEdgeSwipeZones({
    super.key,
    required this.currentIndex,
    required this.child,
  });

  @override
  State<MainTabEdgeSwipeZones> createState() => _MainTabEdgeSwipeZonesState();
}

class _MainTabEdgeSwipeZonesState extends State<MainTabEdgeSwipeZones> {
  double _dragDistance = 0;
  double _dragProgress = 0;
  int? _previewIndex;

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _dragDistance = 0;
      _dragProgress = 0;
      _previewIndex = null;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragDistance += details.primaryDelta ?? 0;
    _updatePreview();
  }

  void _updatePreview() {
    final targetIndex = _targetIndexForDistance(_dragDistance);
    setState(() {
      _previewIndex = targetIndex;
      _dragProgress = targetIndex == null
          ? 0
          : (_dragDistance.abs() / 130).clamp(0.0, 1.0).toDouble();
    });
  }

  int? _targetIndexForDistance(double distance) {
    if (distance.abs() < 8) return null;
    final targetIndex = distance < 0
        ? widget.currentIndex + 1
        : widget.currentIndex - 1;
    if (targetIndex < 0 || targetIndex >= MainTabNavigator._pages.length) {
      return null;
    }
    return targetIndex;
  }

  void _handleSwipe(BuildContext context, DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final hasFastSwipe = velocity.abs() >= 280;
    final hasLongSwipe = _dragDistance.abs() >= 72;

    if (!hasFastSwipe && !hasLongSwipe) {
      _resetPreview();
      return;
    }

    final direction = hasFastSwipe ? velocity : _dragDistance;
    final nextIndex = direction < 0
        ? widget.currentIndex + 1
        : widget.currentIndex - 1;
    if (nextIndex < 0 || nextIndex >= MainTabNavigator._pages.length) {
      _resetPreview();
      return;
    }

    MainTabNavigator.goTo(
      context,
      nextIndex,
      fromIndex: widget.currentIndex,
      animated: true,
    );
    _resetPreview();
  }

  void _handleDragCancel() {
    _resetPreview();
  }

  void _resetPreview() {
    if (!mounted) return;
    setState(() {
      _dragDistance = 0;
      _dragProgress = 0;
      _previewIndex = null;
    });
  }

  Widget _edgeZone(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: (details) => _handleSwipe(context, details),
      onHorizontalDragCancel: _handleDragCancel,
      child: const SizedBox.expand(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MainTabSwipePreview(
          currentIndex: widget.currentIndex,
          previewIndex: _previewIndex,
          progress: _dragProgress,
          dragDistance: _dragDistance,
          child: widget.child,
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 26,
          child: _edgeZone(context),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 26,
          child: _edgeZone(context),
        ),
      ],
    );
  }
}

class MainTabSwipePreview extends StatelessWidget {
  final int currentIndex;
  final int? previewIndex;
  final double progress;
  final double dragDistance;
  final Widget child;

  const MainTabSwipePreview({
    super.key,
    required this.currentIndex,
    required this.previewIndex,
    required this.progress,
    required this.dragDistance,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final targetIndex = previewIndex;
    if (targetIndex == null || progress <= 0) {
      return child;
    }

    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final isNext = targetIndex > currentIndex;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final previewBottomCrop = safeBottom + 124;
    final currentDx = dragDistance.clamp(-width, width).toDouble();
    final targetDx = isNext ? width + currentDx : -width + currentDx;

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: previewBottomCrop,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [Color(0xFF113468), Color(0xFF000022)],
              ),
            ),
            child: IgnorePointer(
              child: ClipRect(
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Transform.translate(
                      offset: Offset(currentDx, 0),
                      child: MainTabPreviewScope(
                        hideBottomNav: true,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: child,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(targetDx, 0),
                      child: MainTabPreviewScope(
                        hideBottomNav: true,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: MainTabNavigator._pages[targetIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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
    if (MainTabPreviewScope.shouldHideBottomNav(context)) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFF1A2340),
      child: BottomNavigationBar(
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
    );
  }
}
