import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/affirmations_controller.dart';
import '../../models/affirmation.dart';

class AffirmationsPage extends StatefulWidget {
  AffirmationsPage({
    super.key,
    AffirmationsController? affirmationsController,
  }) : affirmationsController =
            affirmationsController ?? AffirmationsController();

  final AffirmationsController affirmationsController;

  @override
  State<AffirmationsPage> createState() => _AffirmationsPageState();
}

class _AffirmationsPageState extends State<AffirmationsPage> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.affirmationsController.addListener(_handleControllerChanged);
    widget.affirmationsController.loadAffirmations();
  }

  @override
  void dispose() {
    widget.affirmationsController.removeListener(_handleControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before adding affirmation.')),
      );
      return;
    }

    final success = await widget.affirmationsController.createAffirmation(
      text: _textController.text,
      createdBy: userId,
    );

    if (success) {
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.affirmationsController;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Affirmations',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add affirmation text for the user experience and Gemini prompt flow.',
                        style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading
                      ? null
                      : controller.loadAffirmations,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (controller.errorMessage != null) ...[
              const SizedBox(height: 14),
              Text(
                controller.errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Affirmation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF17201D),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _textController,
                            minLines: 4,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              labelText: 'Affirmation text',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: controller.isSaving ? null : _submit,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  flex: 3,
                  child: _AffirmationsList(controller: controller),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AffirmationsList extends StatelessWidget {
  const _AffirmationsList({required this.controller});

  final AffirmationsController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: SizedBox(
        height: 520,
        child: controller.isLoading && controller.affirmations.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.affirmations.isEmpty
                ? const Center(child: Text('No affirmations added.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: controller.affirmations.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      return _AffirmationRow(
                        affirmation: controller.affirmations[index],
                        isSaving: controller.isSaving,
                        onEdit: () => _showEditDialog(
                          context: context,
                          controller: controller,
                          affirmation: controller.affirmations[index],
                        ),
                        onRemove: () => controller.removeAffirmation(
                          controller.affirmations[index],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required AffirmationsController controller,
    required Affirmation affirmation,
  }) async {
    final textController = TextEditingController(text: affirmation.text);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Affirmation'),
          content: SizedBox(
            width: 520,
            child: TextField(
              controller: textController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Affirmation text',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: controller.isSaving
                  ? null
                  : () async {
                      final success = await controller.updateAffirmation(
                        affirmation: affirmation,
                        text: textController.text,
                      );
                      if (success && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ],
        );
      },
    );

    textController.dispose();
  }
}

class _AffirmationRow extends StatelessWidget {
  const _AffirmationRow({
    required this.affirmation,
    required this.isSaving,
    required this.onEdit,
    required this.onRemove,
  });

  final Affirmation affirmation;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFBFE8D8),
          child: Icon(Icons.format_quote, color: Color(0xFF14211D), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                affirmation.text,
                style: const TextStyle(
                  color: Color(0xFF17201D),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(affirmation.createdAt),
                style: const TextStyle(color: Color(0xFF66736F), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: isSaving ? null : onEdit,
          tooltip: 'Edit affirmation',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: isSaving ? null : onRemove,
          tooltip: 'Remove affirmation',
          color: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
