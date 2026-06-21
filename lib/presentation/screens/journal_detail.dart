import 'package:flutter/material.dart';

import '../../../controllers/journal_controller.dart';
import '../../../models/journal.dart';
import '../../../widgets/gradient_background.dart';
import '../../../widgets/bottom_nav_bar.dart';
import '../../../widgets/button_gradient.dart';

class JournalDetailPage extends StatefulWidget {
  final JournalModel? journal;

  const JournalDetailPage({super.key, this.journal});

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> {
  final JournalController _controller = JournalController();

  late TextEditingController _titleController;
  late TextEditingController _contentController;

  bool _isSaving = false;
  bool get _isEditing => widget.journal != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.journal?.title ?? '');
    _contentController = TextEditingController(
      text: widget.journal?.content ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and journal content.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    String? error;

    if (_isEditing) {
      error = await _controller.updateJournal(
        journalId: widget.journal!.id,
        title: title,
        content: content,
      );
    } else {
      error = await _controller.createJournal(title: title, content: content);
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context, true);
  }

  Future<void> _confirmDelete() async {
    if (!_isEditing) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete Journal',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this journal?',
          style: TextStyle(color: Colors.black),
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

    final error = await _controller.deleteJournal(widget.journal!.id);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pop(context, true);
  }

  void _startVoiceInput() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice-to-text will be added later.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
            children: [
              const Text(
                'Daily reflection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "What's on your mind?",
                style: TextStyle(
                  color: Color(0xFF8AA7D9),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              Container(
                height: 420,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA1AEE2), Color(0xFFEEF2F2)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Title',
                              hintStyle: TextStyle(
                                color: Color(0xFF6C95C6),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _startVoiceInput,
                          icon: const Icon(
                            Icons.mic,
                            color: Color(0xFF6C95C6),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Begin your journey through words.',
                          hintStyle: TextStyle(
                            color: Color(0xFF6C95C6),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: _GradientButton(
                  text: _isSaving ? 'Saving...' : 'Save Entry',
                  onTap: _isSaving ? null : _saveJournal,
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: _GradientButton(
                  text: 'Delete Entry',
                  onTap: _confirmDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _GradientButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.6 : 1,
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: ButtonGradient.decoration(radius: 25),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
