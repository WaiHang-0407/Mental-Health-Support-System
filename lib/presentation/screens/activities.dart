import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  final _searchController = TextEditingController();
  ActivityStatusFilter _statusFilter = ActivityStatusFilter.open;
  _ActivitySortOption _sortOption = _ActivitySortOption.newest;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _searchController.addListener(_handleSearchChanged);
    widget.controller.loadActivities();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleSearchChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectStatusFilter(ActivityStatusFilter filter) {
    setState(() {
      _statusFilter = filter;
    });

    final activities = _filteredActivities(widget.controller.activitiesFor(filter));
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
    final currentActivities = _filteredActivities(
      controller.activitiesFor(_statusFilter),
    );
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
              openCount: controller.countFor(ActivityStatusFilter.open),
              registrationClosedCount: controller.countFor(
                ActivityStatusFilter.registrationClosed,
              ),
              completedCount: controller.countFor(
                ActivityStatusFilter.completed,
              ),
              archivedCount: controller.countFor(ActivityStatusFilter.archived),
              cancelledCount: controller.countFor(
                ActivityStatusFilter.cancelled,
              ),
              onSelected: _selectStatusFilter,
            ),
            const SizedBox(height: 16),
            _ActivityListTools(
              searchController: _searchController,
              sortOption: _sortOption,
              onSortChanged: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
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
                          child: _ActivitiesTable(
                            activities: currentActivities,
                            statusFilter: _statusFilter,
                            selectedActivityId: controller.selectedActivityId,
                            onSelected: (activity) =>
                                controller.selectActivity(activity.id),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 2,
                          child: _ActivityDetails(
                            controller: controller,
                            onEdit: _showEditDialog,
                            onArchive: (activity) => activity.isArchived
                                ? controller.unarchiveActivity(activity.id)
                                : controller.archiveActivity(activity.id),
                            onDelete: (activity) =>
                                controller.deleteActivity(activity.id),
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

  List<CommunityActivity> _filteredActivities(
    List<CommunityActivity> activities,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = activities.where((activity) {
      if (query.isEmpty) {
        return true;
      }
      return _activitySearchValues(activity).any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();

    filtered.sort((left, right) {
      return switch (_sortOption) {
        _ActivitySortOption.newest => _compareDateDesc(left.createdAt, right.createdAt),
        _ActivitySortOption.oldest => _compareDateAsc(left.createdAt, right.createdAt),
        _ActivitySortOption.titleAsc => left.title.toLowerCase().compareTo(right.title.toLowerCase()),
        _ActivitySortOption.titleDesc => right.title.toLowerCase().compareTo(left.title.toLowerCase()),
        _ActivitySortOption.eventSoonest => _compareDateAsc(left.eventDate, right.eventDate),
        _ActivitySortOption.eventLatest => _compareDateDesc(left.eventDate, right.eventDate),
      };
    });

    return filtered;
  }

  List<String> _activitySearchValues(CommunityActivity activity) {
    return [
      activity.title,
      activity.description ?? '',
      activity.venue ?? '',
      activity.status,
      ...activity.sponsorships.map((sponsorship) => sponsorship.sponsorName),
    ];
  }
}

enum _ActivitySortOption {
  newest('Newest created'),
  oldest('Oldest created'),
  titleAsc('Title A-Z'),
  titleDesc('Title Z-A'),
  eventSoonest('Event soonest'),
  eventLatest('Event latest');

  const _ActivitySortOption(this.label);
  final String label;
}

class _ActivityListTools extends StatelessWidget {
  const _ActivityListTools({
    required this.searchController,
    required this.sortOption,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final _ActivitySortOption sortOption;
  final ValueChanged<_ActivitySortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search activities',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<_ActivitySortOption>(
            initialValue: sortOption,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in _ActivitySortOption.values)
                DropdownMenuItem(value: option, child: Text(option.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                onSortChanged(value);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ActivityStatusTabs extends StatelessWidget {
  const _ActivityStatusTabs({
    required this.selectedFilter,
    required this.openCount,
    required this.registrationClosedCount,
    required this.completedCount,
    required this.archivedCount,
    required this.cancelledCount,
    required this.onSelected,
  });

  final ActivityStatusFilter selectedFilter;
  final int openCount;
  final int registrationClosedCount;
  final int completedCount;
  final int archivedCount;
  final int cancelledCount;
  final ValueChanged<ActivityStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ActivityStatusFilter>(
      segments: [
        ButtonSegment(
          value: ActivityStatusFilter.open,
          icon: const Icon(Icons.event_available_outlined),
          label: Text('Open ($openCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.registrationClosed,
          icon: const Icon(Icons.event_busy_outlined),
          label: Text('Closed ($registrationClosedCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.completed,
          icon: const Icon(Icons.task_alt_outlined),
          label: Text('Completed ($completedCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.archived,
          icon: const Icon(Icons.archive_outlined),
          label: Text('Archived ($archivedCount)'),
        ),
        ButtonSegment(
          value: ActivityStatusFilter.cancelled,
          icon: const Icon(Icons.delete_outline),
          label: Text('Cancelled ($cancelledCount)'),
        ),
      ],
      selected: {selectedFilter},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _ActivitiesTable extends StatelessWidget {
  const _ActivitiesTable({
    required this.activities,
    required this.statusFilter,
    required this.selectedActivityId,
    required this.onSelected,
  });

  final List<CommunityActivity> activities;
  final ActivityStatusFilter statusFilter;
  final String? selectedActivityId;
  final ValueChanged<CommunityActivity> onSelected;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.white,
        child: Center(child: Text(_emptyMessage)),
      );
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 10,
                  horizontalMargin: 8,
                  headingRowHeight: 42,
                  dataRowMinHeight: 46,
                  dataRowMaxHeight: 46,
                  showCheckboxColumn: false,
                  headingTextStyle: const TextStyle(
                    color: Color(0xFF3A4541),
                    fontWeight: FontWeight.w800,
                  ),
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Venue')),
                    DataColumn(label: Text('Event')),
                    DataColumn(label: Text('Deadline')),
                    DataColumn(label: Text('Sponsors')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final activity in activities)
                      DataRow(
                        selected: activity.id == selectedActivityId,
                        onSelectChanged: (_) => onSelected(activity),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 118,
                              child: Text(
                                activity.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 96,
                              child: Text(
                                activity.venue ?? '-',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          ),
                          DataCell(Text(_formatDateTime(activity.eventDate))),
                          DataCell(
                            Text(
                              _formatDateTime(activity.registrationDeadline),
                            ),
                          ),
                          DataCell(
                            Text(activity.sponsorships.length.toString()),
                          ),
                          DataCell(_StatusChip(label: activity.status)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String get _emptyMessage {
    return switch (statusFilter) {
      ActivityStatusFilter.open => 'No open community activities found.',
      ActivityStatusFilter.registrationClosed =>
        'No registration-closed community activities found.',
      ActivityStatusFilter.completed =>
        'No completed community activities found.',
      ActivityStatusFilter.archived => 'No archived community activities found.',
      ActivityStatusFilter.cancelled =>
        'No cancelled community activities found.',
    };
  }
}

class _ActivityDetails extends StatelessWidget {
  const _ActivityDetails({
    required this.controller,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final CommunityActivitiesController controller;
  final ValueChanged<CommunityActivity> onEdit;
  final ValueChanged<CommunityActivity> onArchive;
  final ValueChanged<CommunityActivity> onDelete;

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
          if (activity.imageUrl?.isNotEmpty == true) ...[
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: Image.network(activity.imageUrl!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              TextButton.icon(
                onPressed: activity.canEdit ? () => onEdit(activity) : null,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed:
                    activity.isDeleted ? null : () => onArchive(activity),
                icon: Icon(
                  activity.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(activity.isArchived ? 'Unarchive' : 'Archive'),
              ),
              TextButton.icon(
                onPressed: activity.isDeleted ? null : () => onDelete(activity),
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  activity.hasLockedRegistration ? 'Cancel Activity' : 'Delete',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Activity Details',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _ActivityDetailRow(label: 'Status', value: activity.status),
          _ActivityDetailRow(
            label: 'Description',
            value: activity.description,
          ),
          _ActivityDetailRow(label: 'Venue', value: activity.venue),
          _ActivityDetailRow(
            label: 'Event date',
            value: _formatDateTime(activity.eventDate),
          ),
          _ActivityDetailRow(
            label: 'Registration deadline',
            value: _formatDateTime(activity.registrationDeadline),
          ),
          _ActivityDetailRow(
            label: 'Max participants',
            value: activity.maxParticipants?.toString(),
          ),
          _ActivityDetailRow(
            label: 'Sponsorships',
            value: activity.sponsorships.length.toString(),
          ),
          _ActivityDetailRow(
            label: 'Created on',
            value: _formatDate(activity.createdAt),
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
              _ParticipantRow(
                participant: participant,
                onTap: () => _showParticipantDetails(context, participant),
              ),
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

  Future<void> _showParticipantDetails(
    BuildContext context,
    ActivityParticipant participant,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ParticipantDetailsDialog(participant: participant),
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

class _ActivityDetailRow extends StatelessWidget {
  const _ActivityDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66736F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue == null || displayValue.isEmpty
                  ? '-'
                  : displayValue,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
  Uint8List? _coverImageBytes;
  String? _coverImageFileName;
  String? _coverImageMimeType;
  String? _existingCoverImageUrl;
  DateTime? _eventDate;

  bool get _isEditing => widget.activity != null;
  bool get _isScheduleLocked => widget.activity?.hasLockedRegistration ?? false;

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
    _existingCoverImageUrl = activity.imageUrl;
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
    if (_isScheduleLocked) {
      return;
    }

    final minDate = widget.controller.minimumEventDate;
    final current = _eventDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _eventDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      return;
    }

    final file = result.files.single;
    setState(() {
      _coverImageBytes = file.bytes;
      _coverImageFileName = file.name;
      _coverImageMimeType = _mimeTypeFor(file.extension);
    });
  }

  void _removeCoverImage() {
    setState(() {
      _coverImageBytes = null;
      _coverImageFileName = null;
      _coverImageMimeType = null;
      _existingCoverImageUrl = null;
    });
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
    if (!_validateLockedCapacity()) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('Sign in again before creating an activity.');
      return;
    }

    final input = CreateCommunityActivityInput(
      title: _isScheduleLocked
          ? widget.activity!.title
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      venue: _venueController.text.trim(),
      eventDate: _isScheduleLocked
          ? widget.activity!.eventDate ?? eventDate
          : eventDate,
      registrationDeadline: _isScheduleLocked
          ? widget.activity!.registrationDeadline ??
              widget.controller.registrationDeadlineFor(eventDate)
          : widget.controller.registrationDeadlineFor(eventDate),
      createdBy: userId,
      maxParticipants: _maxParticipantsForSubmit(),
      coverImageUrl: _existingCoverImageUrl,
      coverImageBytes: _coverImageBytes,
      coverImageFileName: _coverImageFileName,
      coverImageMimeType: _coverImageMimeType,
      sponsorshipIds: _isScheduleLocked
          ? widget.activity?.sponsorships.map((sponsorship) => sponsorship.id).toList() ??
              const []
          : _selectedSponsorshipIds.toList(),
    );
    final activity = widget.activity;
    final scheduleChanged = activity != null &&
        !_sameDateTime(activity.eventDate, eventDate);
    final success = activity == null
        ? await widget.controller.createActivity(input)
        : await widget.controller.updateActivity(
            activityId: activity.id,
            input: input,
            enforceScheduleRules: scheduleChanged,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      _showSnack(widget.controller.errorMessage ?? 'Unable to save changes.');
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateLockedCapacity() {
    if (!_isScheduleLocked) {
      return true;
    }

    final current = widget.activity?.maxParticipants;
    final updated = int.tryParse(_maxParticipantsController.text.trim());
    if (current != null && updated != null && updated < current) {
      _showSnack('Capacity can only be increased after registration closes.');
      return false;
    }
    return true;
  }

  int? _maxParticipantsForSubmit() {
    final updated = int.tryParse(_maxParticipantsController.text.trim());
    if (!_isScheduleLocked) {
      return updated;
    }

    final current = widget.activity?.maxParticipants;
    if (current == null) {
      return updated;
    }
    if (updated == null) {
      return current;
    }
    return updated < current ? current : updated;
  }

  @override
  Widget build(BuildContext context) {
    final eventDate = _eventDate;
    final registrationDeadline = eventDate == null
        ? null
        : widget.controller.registrationDeadlineFor(eventDate);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 780),
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
                  _isScheduleLocked
                      ? 'Registration is closed. Only description, venue, and increased capacity can be changed.'
                      : 'Activity date must be at least 10 days from today. Registration deadline is fixed 2 days before.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final twoColumns = constraints.maxWidth >= 760;
                      final detailsSection = _ActivityFormSection(
                        icon: Icons.edit_note_outlined,
                        title: 'Details',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _titleController,
                              enabled: !_isScheduleLocked,
                              decoration: const InputDecoration(
                                labelText: 'Title',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              minLines: 5,
                              maxLines: 7,
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _venueController,
                              decoration: const InputDecoration(
                                labelText: 'Venue',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: _required,
                            ),
                          ],
                        ),
                      );

                      final coverSection = _ActivityFormSection(
                        icon: Icons.image_outlined,
                        title: 'Cover Photo',
                        child: _CoverImagePicker(
                          existingUrl: _existingCoverImageUrl,
                          bytes: _coverImageBytes,
                          fileName: _coverImageFileName,
                          onPick: _pickCoverImage,
                          onRemove: _removeCoverImage,
                        ),
                      );

                      final scheduleSection = _ActivityFormSection(
                        icon: Icons.event_outlined,
                        title: 'Schedule',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _isScheduleLocked ? null : _pickEventDate,
                              icon: const Icon(Icons.calendar_month_outlined),
                              label: Text(
                                eventDate == null
                                    ? 'Select activity date and time'
                                    : _formatDateTime(eventDate),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DeadlineSummary(
                              value: registrationDeadline == null
                                  ? '-'
                                  : _formatDateTime(registrationDeadline),
                            ),
                          ],
                        ),
                      );

                      final capacitySection = _ActivityFormSection(
                        icon: Icons.people_alt_outlined,
                        title: 'Capacity',
                        child: TextFormField(
                          controller: _maxParticipantsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Max participants',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      );

                      final sponsorshipSection = _ActivityFormSection(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Sponsorships',
                        child: _selectableSponsorships.isEmpty
                            ? const _EmptyPanel(
                                text:
                                    'No available sponsorships. Add sponsorships from the Sponsorships page first.',
                              )
                            : Column(
                                children: [
                                  for (final sponsorship
                                      in _selectableSponsorships)
                                    CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: _selectedSponsorshipIds.contains(
                                        sponsorship.id,
                                      ),
                                      onChanged: _isScheduleLocked
                                          ? null
                                          : (selected) {
                                              setState(() {
                                                if (selected == true) {
                                                  _selectedSponsorshipIds.add(
                                                    sponsorship.id,
                                                  );
                                                } else {
                                                  _selectedSponsorshipIds.remove(
                                                    sponsorship.id,
                                                  );
                                                }
                                              });
                                            },
                                      title: Text(
                                        sponsorship.sponsorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        _sponsorshipSubtitle(sponsorship),
                                        style: const TextStyle(
                                          color: Color(0xFF66736F),
                                        ),
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                    ),
                                ],
                              ),
                      );

                      final content = twoColumns
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: detailsSection),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    children: [
                                      coverSection,
                                      const SizedBox(height: 14),
                                      scheduleSection,
                                      const SizedBox(height: 14),
                                      capacitySection,
                                      const SizedBox(height: 14),
                                      sponsorshipSection,
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                detailsSection,
                                const SizedBox(height: 14),
                                coverSection,
                                const SizedBox(height: 14),
                                scheduleSection,
                                const SizedBox(height: 14),
                                capacitySection,
                                const SizedBox(height: 14),
                                sponsorshipSection,
                              ],
                            );

                      return ListView(children: [content]);
                    },
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

  bool _sameDateTime(DateTime? left, DateTime? right) {
    if (left == null || right == null) {
      return left == right;
    }
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day &&
        left.hour == right.hour &&
        left.minute == right.minute;
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
    final assignmentCount = sponsorship.activityIds.length;
    final assignmentLabel =
        assignmentCount == 1 ? 'Used by 1 activity' : 'Used by $assignmentCount activities';
    return '$assignmentLabel | ${sponsorship.products.length} products';
  }

  String _mimeTypeFor(String? extension) {
    return switch ((extension ?? '').toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      _ => 'application/octet-stream',
    };
  }
}

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({
    required this.existingUrl,
    required this.bytes,
    required this.fileName,
    required this.onPick,
    required this.onRemove,
  });

  final String? existingUrl;
  final Uint8List? bytes;
  final String? fileName;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        bytes != null || (existingUrl != null && existingUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            height: 150,
            color: const Color(0xFFE8ECEA),
            child: hasImage
                ? bytes != null
                    ? Image.memory(bytes!, fit: BoxFit.cover)
                    : Image.network(existingUrl!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Color(0xFF66736F),
                      size: 34,
                    ),
                  ),
          ),
        ),
        if (fileName?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            fileName!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(hasImage ? 'Replace Cover' : 'Select Cover'),
              ),
            ),
            if (hasImage) ...[
              const SizedBox(width: 8),
              IconButton.outlined(
                onPressed: onRemove,
                tooltip: 'Remove cover',
                icon: const Icon(Icons.close),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ActivityFormSection extends StatelessWidget {
  const _ActivityFormSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Icon(icon, size: 19, color: const Color(0xFF1F7A64)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF17201D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DeadlineSummary extends StatelessWidget {
  const _DeadlineSummary({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 18,
            color: Color(0xFF66736F),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Registration deadline',
              style: TextStyle(
                color: Color(0xFF66736F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.participant,
    required this.onTap,
  });

  final ActivityParticipant participant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
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
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }
}

class _ParticipantDetailsDialog extends StatelessWidget {
  const _ParticipantDetailsDialog({required this.participant});

  final ActivityParticipant participant;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = participant.avatarUrl;

    return AlertDialog(
      title: const Text('Participant Details'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFBFE8D8),
                  backgroundImage: avatarUrl == null || avatarUrl.isEmpty
                      ? null
                      : NetworkImage(avatarUrl),
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const Icon(
                          Icons.person_outline,
                          color: Color(0xFF14211D),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        participant.name ?? 'Unnamed patient',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _StatusChip(
                        label: participant.isCancelled
                            ? 'Cancelled'
                            : 'Registered',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ParticipantDetailRow(
              label: 'Patient ID',
              value: participant.patientId,
            ),
            _ParticipantDetailRow(label: 'Gender', value: participant.gender),
            _ParticipantDetailRow(
              label: 'Date of birth',
              value: _formatDate(participant.dob),
            ),
            _ParticipantDetailRow(label: 'Phone', value: participant.phoneNo),
            _ParticipantDetailRow(
              label: 'Condition',
              value: participant.condition,
            ),
            _ParticipantDetailRow(
              label: 'Favorite animal',
              value: participant.favAnimal,
            ),
            _ParticipantDetailRow(
              label: 'Favorite activity',
              value: participant.favActivity,
            ),
            _ParticipantDetailRow(
              label: 'Registered on',
              value: _formatDate(participant.createdAt),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _ParticipantDetailRow extends StatelessWidget {
  const _ParticipantDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66736F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue == null || displayValue.isEmpty
                  ? '-'
                  : displayValue,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = switch (label) {
      'Active' => (
          background: const Color(0xFFE8F3EF),
          foreground: const Color(0xFF1F7A64),
        ),
      'Registration Closed' => (
          background: const Color(0xFFFFF3D6),
          foreground: const Color(0xFF8A5A00),
        ),
      'Completed' => (
          background: const Color(0xFFE8EEF7),
          foreground: const Color(0xFF2F5D9B),
        ),
      'Archived' => (
          background: const Color(0xFFF0F4F2),
          foreground: const Color(0xFF66736F),
        ),
      'Cancelled' || 'Deleted' => (
          background: const Color(0xFFF4EDEA),
          foreground: const Color(0xFF8A4B38),
        ),
      _ => (
          background: const Color(0xFFF0F4F2),
          foreground: const Color(0xFF66736F),
        ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: colors.foreground,
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

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${_formatDate(value)} $hour:$minute';
}

int _compareDateAsc(DateTime? left, DateTime? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }
  return left.compareTo(right);
}

int _compareDateDesc(DateTime? left, DateTime? right) {
  return _compareDateAsc(right, left);
}
