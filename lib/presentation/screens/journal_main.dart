import 'package:flutter/material.dart';

import '../../controllers/journal_controller.dart';
import '../../models/journal.dart';

import '../../widgets/gradient_background.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/button_gradient.dart';

import '../../services/auth_service.dart';
import 'journal_detail.dart';
import 'weekly_report.dart';
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

  final Set<String> _selectedJournalIds = {};

  bool get _selectionMode => _selectedJournalIds.isNotEmpty;

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

  void _openWeeklyReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
    );
  }

  Future<void> _logout() async {
    await authService.signOut();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  void _toggleJournalSelection(String journalId) {
    setState(() {
      if (_selectedJournalIds.contains(journalId)) {
        _selectedJournalIds.remove(journalId);
      } else {
        _selectedJournalIds.add(journalId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedJournalIds.clear();
    });
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedJournalIds.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Journals',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete $count selected journal(s)?',
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await _controller.deleteMultipleJournals(
      _selectedJournalIds.toList(),
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() {
      _selectedJournalIds.clear();
      _isLoading = true;
    });

    await _loadJournals();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _hasJournalToday() {
    final today = DateTime.now();

    return _journals.any((journal) {
      final createdAt = journal.createdAt;
      if (createdAt == null) return false;

      return _isSameDay(createdAt.toLocal(), today);
    });
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();

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

    return '${localDate.day} ${months[localDate.month]}';
  }

  BoxDecoration _buttonDecoration({bool selected = false}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [ButtonGradient.start, ButtonGradient.end],
      ),
      borderRadius: BorderRadius.circular(20),
      border: selected ? Border.all(color: Colors.white, width: 3) : null,
      boxShadow: selected
          ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.45),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
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
      child: MainTabSwipeWrapper(
        currentIndex: 1,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: _selectionMode
                ? Text(
                    '${_selectedJournalIds.length} selected',
                    style: const TextStyle(color: Colors.white),
                  )
                : const Text(
                    'Journal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
            leading: _selectionMode
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _clearSelection,
                  )
                : null,
            actions: [
              if (_selectionMode)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _confirmDeleteSelected,
                )
              else
                IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
            ],
          ),
          bottomNavigationBar: BottomNavBar(currentIndex: 1),
          body: _isLoading
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
                      onTap: _selectionMode ? null : _openWeeklyReport,
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

                    if (!_hasJournalToday())
                      GestureDetector(
                        onTap: _selectionMode
                            ? null
                            : () => _openJournalDetail(),
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

                    ..._journals.map((journal) {
                      final isSelected = _selectedJournalIds.contains(
                        journal.id,
                      );

                      return GestureDetector(
                        onLongPress: () => _toggleJournalSelection(journal.id),
                        onTap: () {
                          if (_selectionMode) {
                            _toggleJournalSelection(journal.id);
                          } else {
                            _openJournalDetail(journal: journal);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: _buttonDecoration(selected: isSelected),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectionMode) ...[
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : ButtonGradient.text,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
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
                                      style: _buttonTitleStyle.copyWith(
                                        fontSize: 16,
                                      ),
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
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ),
    );
  }
}
