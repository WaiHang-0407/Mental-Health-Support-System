import 'package:flutter/material.dart';

import '../../controllers/journal_controller.dart';
import '../../models/journal.dart';

import '../../widgets/gradient_background.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/button_gradient.dart';

import '../../services/auth_service.dart';
import 'journal_detail.dart';
import 'login.dart';

class JournalMainPage extends StatefulWidget {
  const JournalMainPage({super.key});

  @override
  State<JournalMainPage> createState() => _JournalMainPageState();
}

class _JournalMainPageState extends State<JournalMainPage> {
  final AuthService authService = AuthService();
  final JournalController _controller = JournalController();

  bool _isLoading = true;
  List<JournalModel> _journals = [];

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    final journals = await _controller.getJournals();

    if (!mounted) return;

    setState(() {
      _journals = journals;
      _isLoading = false;
    });
  }

  Future<void> _openJournalDetail({JournalModel? journal}) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JournalDetailPage(journal: journal)),
    );

    if (shouldRefresh == true) {
      _loadJournals();
    }
  }

  Future<void> _logout() async {
    await authService.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month]}';
  }

  BoxDecoration _buttonDecoration() {
    return ButtonGradient.decoration();
  }

  TextStyle get _buttonTitleStyle {
    return const TextStyle(
      color: ButtonGradient.text,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
  }

  TextStyle get _buttonBodyStyle {
    return const TextStyle(
      color: ButtonGradient.text,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
        floatingActionButton: FloatingActionButton(
          backgroundColor: ButtonGradient.start,
          onPressed: () => _openJournalDetail(),
          child: const Icon(Icons.add, color: ButtonGradient.text),
        ),
        body: MainTabSwipeArea(
          currentIndex: 1,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 100),
                  children: [
                    const Text(
                      "Let's start journalling!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // TODO: Navigate to Weekly Report page later
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _buttonDecoration(),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Weekly Report',
                              style: _buttonTitleStyle.copyWith(fontSize: 20),
                            ),
                            Text('See all', style: _buttonBodyStyle),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_journals.isEmpty)
                      GestureDetector(
                        onTap: () => _openJournalDetail(),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: _buttonDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(DateTime.now()),
                                style: _buttonTitleStyle,
                              ),
                              const SizedBox(height: 8),
                              Text("Still empty...", style: _buttonBodyStyle),
                            ],
                          ),
                        ),
                      ),
                    ..._journals.map(
                      (journal) => GestureDetector(
                        onTap: () => _openJournalDetail(journal: journal),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: _buttonDecoration(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatDate(
                                  journal.createdAt ?? DateTime.now(),
                                ),
                                style: _buttonTitleStyle,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                journal.title?.trim().isNotEmpty == true
                                    ? journal.title!
                                    : 'Untitled Journal',
                                style: _buttonTitleStyle.copyWith(fontSize: 16),
                              ),
                              if (journal.emotion != null &&
                                  journal.emotion!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Mood: ${journal.emotion}',
                                  style: _buttonBodyStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
