import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/community_activities_controller.dart';
import '../../models/community_activity.dart';

class ActivitiesPage extends StatefulWidget {
  ActivitiesPage({
    super.key,
    CommunityActivitiesController? controller,
  }) : controller = controller ?? CommunityActivitiesController();

  final CommunityActivitiesController controller;

  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  ActivityStatusFilter _statusFilter = ActivityStatusFilter.active;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    widget.controller.loadActivities();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectStatusFilter(ActivityStatusFilter filter) {
    setState(() {
      _statusFilter = filter;
    });

    final activities = widget.controller.activitiesFor(filter);
    if (activities.isNotEmpty) {
      widget.controller.selectActivity(activities.first.id);
    } else {
      widget.controller.clearSelection();
    }
  }

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ActivityFormDialog(controller: widget.controller),
    );
  }

  Future<void> _showEditDialog(CommunityActivity activity) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ActivityFormDialog(
        controller: widget.controller,
        activity: activity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final currentActivities = controller.activitiesFor(_statusFilter);
    final selectedActivity = controller.selectedActivity;
    final selectedInCurrentTab = selectedActivity != null &&
        currentActivities.any((activity) => activity.id == selectedActivity.id);
    if (selectedActivity != null && !selectedInCurrentTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          controller.clearSelection();
        }
      });
    }

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
                        'Activities',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create community activities, manage sponsorships, and view participants.',
                        style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading ? null : controller.loadActivities,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Activity'),
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
            _ActivityStatusTabs(
              selectedFilter: _statusFilter,
              activeCount: controller.countFor(ActivityStatusFilter.active),
              archivedCount: controller.countFor(ActivityStatusFilter.archived),
              deletedCount: controller.countFor(ActivityStatusFilter.deleted),
              onSelected: _selectStatusFilter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.isLoading && controller.activities.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _ActivitiesList(
                            controller: controller,
                            activities: currentActivities,
                            statusFilter: _statusFilter,
                            onEditActivity: _showEditDialog,
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 2,
                          child: _ActivityDetails(controller: controller),
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

class _ActivityStatusTabs extends StatelessWidget {
  const _ActivityStatusTabs({
    required this.selectedFilter,
    required this.activeCount,
    required this.archivedCount,
    required this.deletedCount,
    required this.onSelected,
  });

  final ActivityStatusFilter selectedFilter;
  final int activeCount;
  final int archivedCount;
  final int deletedCount;
  final ValueChanged<ActivityStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ActivityStatusFilter>(
      segments: [
        ButtonSegment(
          value: ActivityStatusFilter.active,
          icon: const Icon(Icons.event_available_outlined),
          label: Text('Active ($activeCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.archived,
          icon: const Icon(Icons.archive_outlined),
          label: Text('Archived ($archivedCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.deleted,
          icon: const Icon(Icons.delete_outline),
          label: Text('Deleted ($deletedCount)'),
        ),
      ],
      selected: {selectedFilter},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _ActivitiesList extends StatelessWidget {
  const _ActivitiesList({
    required this.controller,
    required this.activities,
    required this.statusFilter,
    required this.onEditActivity,
  });

  final CommunityActivitiesController controller;
  final List<CommunityActivity> activities;
  final ActivityStatusFilter statusFilter;
  final ValueChanged<CommunityActivity> onEditActivity;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        child: Center(child: Text(_emptyMessage)),
      );
    }

    return ListView.separated(
      itemCount: activities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _ActivityCard(
          activity: activity,
          selected: activity.id == controller.selectedActivityId,
          onSelect: () => controller.selectActivity(activity.id),
          onEdit: activity.isDeleted ? null : () => onEditActivity(activity),
          archiveLabel: activity.isArchived ? 'Unarchive' : 'Archive',
          onArchive: activity.isDeleted
              ? null
              : activity.isArchived
                  ? () => controller.unarchiveActivity(activity.id)
                  : () => controller.archiveActivity(activity.id),
          onDelete: activity.isDeleted
              ? null
              : () => controller.deleteActivity(activity.id),
        );
      },
    );
  }

  String get _emptyMessage {
    return switch (statusFilter) {
      ActivityStatusFilter.active => 'No active community activities found.',
      ActivityStatusFilter.archived => 'No archived community activities found.',
      ActivityStatusFilter.deleted => 'No deleted community activities found.',
    };
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.archiveLabel,
    required this.onArchive,
    required this.onDelete,
  });

  final CommunityActivity activity;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final String archiveLabel;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: selected ? const Color(0xFFE8F3EF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        side: BorderSide(
          color: selected ? const Color(0xFF1F7A64) : const Color(0xFFE8ECEA),
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      activity.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF17201D),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(label: activity.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                activity.description ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF66736F)),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _InfoPill(icon: Icons.place_outlined, text: activity.venue ?? '-'),
                  _InfoPill(
                    icon: Icons.event_outlined,
                    text: _formatDate(activity.eventDate),
                  ),
                  _InfoPill(
                    icon: Icons.how_to_reg_outlined,
                    text: _formatDate(activity.registrationDeadline),
                  ),
                  _InfoPill(
                    icon: Icons.volunteer_activism_outlined,
                    text: '${activity.sponsorships.length} sponsorships',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onArchive,
                    icon: Icon(
                      activity.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    label: Text(archiveLabel),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({required this.controller});

  final CommunityActivitiesController controller;

  @override
  Widget build(BuildContext context) {
    final activity = controller.selectedActivity;
    if (activity == null) {
      return const Card(
        elevation: 0,
        color: Colors.white,
        child: Center(child: Text('Select an activity.')),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            activity.title,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Participants: ${controller.participants.length}',
            style: const TextStyle(color: Color(0xFF66736F)),
          ),
          const SizedBox(height: 18),
          const Text(
            'Participants',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (controller.participants.isEmpty)
            const _EmptyPanel(text: 'No participants registered yet.')
          else
            for (final participant in controller.participants)
              _ParticipantRow(participant: participant),
          const SizedBox(height: 22),
          const Text(
            'Sponsorships',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (activity.sponsorships.isEmpty)
            const _EmptyPanel(text: 'No sponsorships added.')
          else
            for (final sponsorship in activity.sponsorships)
              _SponsorshipPanel(
                sponsorship: sponsorship,
              ),
        ],
      ),
    );
  }
}

class _SponsorshipPanel extends StatelessWidget {
  const _SponsorshipPanel({
    required this.sponsorship,
  });

  final ActivitySponsorship sponsorship;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sponsorship.sponsorName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(label: sponsorship.status),
            ],
          ),
          if ((sponsorship.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              sponsorship.description!,
              style: const TextStyle(color: Color(0xFF66736F)),
            ),
          ],
          const SizedBox(height: 8),
          for (final product in sponsorship.products)
            _ProductTile(product: product),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
  });

  final SponsorshipProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(
              width: 54,
              height: 54,
              child: imageUrl == null || imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE8ECEA),
                      child: Icon(Icons.image_outlined),
                    )
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  product.status,
                  style: const TextStyle(color: Color(0xFF66736F), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityFormDialog extends StatefulWidget {
  const _ActivityFormDialog({
    required this.controller,
    this.activity,
  });

  final CommunityActivitiesController controller;
  final CommunityActivity? activity;

  @override
  State<_ActivityFormDialog> createState() => _ActivityFormDialogState();
}

class _ActivityFormDialogState extends State<_ActivityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final Set<String> _selectedSponsorshipIds = {};
  DateTime? _eventDate;

  bool get _isEditing => widget.activity != null;

  @override
  void initState() {
    super.initState();

    final activity = widget.activity;
    if (activity == null) {
      return;
    }

    _titleController.text = activity.title;
    _descriptionController.text = activity.description ?? '';
    _venueController.text = activity.venue ?? '';
    _maxParticipantsController.text = activity.maxParticipants?.toString() ?? '';
    _eventDate = activity.eventDate;
    _selectedSponsorshipIds.addAll(
      activity.sponsorships
          .where((sponsorship) => !sponsorship.isDeleted)
          .map((sponsorship) => sponsorship.id),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _pickEventDate() async {
    final minDate = widget.controller.minimumEventDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final eventDate = _eventDate;
    if (eventDate == null) {
      _showSnack('Select the activity date.');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('Sign in again before creating an activity.');
      return;
    }

    final input = CreateCommunityActivityInput(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      venue: _venueController.text.trim(),
      eventDate: eventDate,
      registrationDeadline: widget.controller.registrationDeadlineFor(eventDate),
      createdBy: userId,
      maxParticipants: int.tryParse(_maxParticipantsController.text.trim()),
      sponsorshipIds: _selectedSponsorshipIds.toList(),
    );
    final activity = widget.activity;
    final success = activity == null
        ? await widget.controller.createActivity(input)
        : await widget.controller.updateActivity(
            activityId: activity.id,
            input: input,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = _eventDate;
    final registrationDeadline = eventDate == null
        ? null
        : widget.controller.registrationDeadlineFor(eventDate);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing
                      ? 'Edit Community Activity'
                      : 'Create Community Activity',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Activity date must be at least 10 days from today. Registration deadline is fixed 2 days before.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 3,
                        maxLines: 4,
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _venueController,
                        decoration: const InputDecoration(
                          labelText: 'Venue',
                          border: OutlineInputBorder(),
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickEventDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(
                                eventDate == null
                                    ? 'Select activity date'
                                    : 'Activity: ${_formatDate(eventDate)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              registrationDeadline == null
                                  ? 'Registration deadline: -'
                                  : 'Registration deadline: ${_formatDate(registrationDeadline)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _maxParticipantsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max participants',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Sponsorships',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      if (_selectableSponsorships.isEmpty)
                        const _EmptyPanel(
                          text:
                              'No available sponsorships. Add sponsorships from the Sponsorships page first.',
                        )
                      else
                        for (final sponsorship in _selectableSponsorships)
                          CheckboxListTile(
                            value: _selectedSponsorshipIds.contains(
                              sponsorship.id,
                            ),
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedSponsorshipIds.add(sponsorship.id);
                                } else {
                                  _selectedSponsorshipIds.remove(sponsorship.id);
                                }
                              });
                            },
                            title: Text(sponsorship.sponsorName),
                            subtitle: Text(
                              _sponsorshipSubtitle(sponsorship),
                              style: const TextStyle(color: Color(0xFF66736F)),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: widget.controller.isSaving ? null : _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_isEditing ? 'Save Changes' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Required.';
    }
    return null;
  }

  List<ActivitySponsorship> get _selectableSponsorships {
    final activity = widget.activity;
    final current = activity?.sponsorships
            .where((sponsorship) => !sponsorship.isDeleted)
            .toList() ??
        const <ActivitySponsorship>[];

    return [
      ...current,
      ...widget.controller.availableSponsorships.where(
        (sponsorship) =>
            !current.any((currentItem) => currentItem.id == sponsorship.id),
      ),
    ];
  }

  String _sponsorshipSubtitle(ActivitySponsorship sponsorship) {
    final assigned = sponsorship.activityId != null;
    final assignmentLabel = assigned ? 'Assigned to this activity' : 'Available';
    return '$assignmentLabel | ${sponsorship.products.length} products';
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.participant});

  final ActivityParticipant participant;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFBFE8D8),
        child: Icon(Icons.person_outline, color: Color(0xFF14211D)),
      ),
      title: Text(participant.name ?? 'Unnamed patient'),
      subtitle: Text(
        [
          participant.gender ?? '-',
          participant.phoneNo ?? '-',
          participant.isCancelled ? 'Cancelled' : 'Registered',
        ].join(' | '),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F2),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: const Color(0xFF1F7A64)),
            const SizedBox(width: 6),
            Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final active = label == 'Active';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F3EF) : const Color(0xFFF4EDEA),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF1F7A64) : const Color(0xFF8A4B38),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F7F8),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF66736F)),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
