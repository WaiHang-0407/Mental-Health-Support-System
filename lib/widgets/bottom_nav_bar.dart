import 'package:flutter/material.dart';
import '../presentation/screens/home_patient.dart';
import '../presentation/screens/journal_main.dart';
import '../presentation/screens/chat_main.dart';
import '../presentation/screens/activity_main.dart';
import '../presentation/screens/community.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return; // already on this page

    final pages = [
      const HomePatientPage(),
      const JournalMainPage(),
      const ChatMainPage(),
      const ActivityMainPage(),
      const CommunityPage(),
    ];

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => pages[index],
        transitionDuration: Duration.zero, // instant switch like a real nav bar
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onTap(context, index),
      type: BottomNavigationBarType.fixed, // needed for 5+ items
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      backgroundColor: const Color(0xFF1A2340), // match your dark theme
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
    );
  }
}