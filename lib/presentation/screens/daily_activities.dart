import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/daily_activities_controller.dart';
import '../../models/daily_activity.dart';

class DailyActivitiesPage extends StatefulWidget {
  DailyActivitiesPage({
    super.key,
    DailyActivitiesController? dailyActivitiesController,
  }) : dailyActivitiesController =
            dailyActivitiesController ?? DailyActivitiesController();

  final DailyActivitiesController dailyActivitiesController;

  @override
  State<DailyActivitiesPage> createState() => _DailyActivitiesPageState();
}

class _DailyActivitiesPageState extends State<DailyActivitiesPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.dailyActivitiesController.addListener(_handleControllerChanged);
    widget.dailyActivitiesController.loadDailyActivities();
  }

  @override
  void dispose() {
    widget.dailyActivitiesController.removeListener(_handleControllerChanged);
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again before adding activity.')),
      );
      return;
    }

    final success =
        await widget.dailyActivitiesController.createDailyActivity(
      DailyActivity(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        durationMinutes: int.tryParse(_durationController.text.trim()),
        createdBy: userId,
      ),
    );

    if (!success) return;
    _titleController.clear();
    _descriptionController.clear();
    _durationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.dailyActivitiesController;

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
                        'Daily Activities',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create simple text suggestions like meditating for 5 minutes or walking for 10 minutes.',
                        style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading
                      ? null
                      : controller.loadDailyActivities,
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _DailyActivityForm(
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      durationController: _durationController,
                      isSaving: controller.isSaving,
                      onSubmit: _submit,
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    flex: 3,
                    child: _DailyActivitiesList(
                      controller: controller,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyActivityForm extends StatelessWidget {
  const _DailyActivityForm({
    required this.titleController,
    required this.descriptionController,
    required this.durationController,
    required this.isSaving,
    required this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController durationController;
  final bool isSaving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Daily Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17201D),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Activity',
                hintText: 'Meditate for 5 minutes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Details',
                hintText: 'Sit comfortably and focus on your breathing.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration',
                suffixText: 'mins',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSubmit,
                icon: const Icon(Icons.add),
                label: const Text('Add Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyActivitiesList extends StatelessWidget {
  const _DailyActivitiesList({required this.controller});

  final DailyActivitiesController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: controller.isLoading && controller.dailyActivities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : controller.dailyActivities.isEmpty
              ? const Center(child: Text('No daily activities added.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: controller.dailyActivities.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final activity = controller.dailyActivities[index];
                    return _DailyActivityRow(
                      activity: activity,
                      isSaving: controller.isSaving,
                      onEdit: () => _showEditDialog(
                        context: context,
                        controller: controller,
                        activity: activity,
                      ),
                      onToggleActive: () => controller.setActive(
                        activity,
                        !activity.isActive,
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _showEditDialog({
    required BuildContext context,
    required DailyActivitiesController controller,
    required DailyActivity activity,
  }) async {
    final titleController = TextEditingController(text: activity.title);
    final descriptionController =
        TextEditingController(text: activity.description);
    final durationController = TextEditingController(
      text: activity.durationMinutes?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
              title: const Text('Edit Daily Activity'),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Activity title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Activity instructions',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          suffixText: 'mins',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
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
                          final success =
                              await controller.updateDailyActivity(
                            DailyActivity(
                              id: activity.id,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              durationMinutes: int.tryParse(
                                durationController.text.trim(),
                              ),
                              isActive: activity.isActive,
                              createdBy: activity.createdBy,
                              createdAt: activity.createdAt,
                            ),
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

    titleController.dispose();
    descriptionController.dispose();
    durationController.dispose();
  }
}

class _DailyActivityRow extends StatelessWidget {
  const _DailyActivityRow({
    required this.activity,
    required this.isSaving,
    required this.onEdit,
    required this.onToggleActive,
  });

  final DailyActivity activity;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: activity.isActive
              ? const Color(0xFFBFE8D8)
              : const Color(0xFFE4E8E6),
          child: Icon(
            Icons.self_improvement_outlined,
            color: activity.isActive
                ? const Color(0xFF14211D)
                : const Color(0xFF66736F),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      style: const TextStyle(
                        color: Color(0xFF17201D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusBadge(isActive: activity.isActive),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                activity.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF66736F), height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (activity.durationMinutes != null)
                    _InfoChip('${activity.durationMinutes} min'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: isSaving ? null : onEdit,
          tooltip: 'Edit daily activity',
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          onPressed: isSaving ? null : onToggleActive,
          tooltip: activity.isActive ? 'Deactivate' : 'Restore',
          color: activity.isActive
              ? Theme.of(context).colorScheme.error
              : const Color(0xFF1F7A55),
          icon: Icon(
            activity.isActive
                ? Icons.visibility_off_outlined
                : Icons.restore_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE5F6EF) : const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? const Color(0xFF1F7A55) : const Color(0xFF66736F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF66736F),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
