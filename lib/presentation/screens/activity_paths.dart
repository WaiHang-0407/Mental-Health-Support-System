import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/activity_paths_controller.dart';
import '../../models/activity_path.dart';

class ActivityPathsPage extends StatefulWidget {
  ActivityPathsPage({
    super.key,
    ActivityPathsController? controller,
  }) : controller = controller ?? ActivityPathsController();

  final ActivityPathsController controller;

  @override
  State<ActivityPathsPage> createState() => _ActivityPathsPageState();
}

class _ActivityPathsPageState extends State<ActivityPathsPage> {
  final _searchController = TextEditingController();
  ActivityPathStatusFilter _statusFilter = ActivityPathStatusFilter.active;
  _ActivityPathSearchField _searchField = _ActivityPathSearchField.all;
  _ActivityPathSortOption _sortOption = _ActivityPathSortOption.newest;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _searchController.addListener(_handleSearchChanged);
    widget.controller.loadActivityPaths();
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

  void _selectStatusFilter(ActivityPathStatusFilter filter) {
    setState(() {
      _statusFilter = filter;
    });

    final paths = _filteredPaths(widget.controller.pathsFor(filter));
    if (paths.isNotEmpty) {
      widget.controller.selectPath(paths.first.id);
    } else {
      widget.controller.clearSelection();
    }
  }

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ActivityPathFormDialog(controller: widget.controller),
    );
  }

  Future<void> _showEditDialog(ActivityPath path) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ActivityPathFormDialog(
        controller: widget.controller,
        activityPath: path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final currentPaths = _filteredPaths(controller.pathsFor(_statusFilter));
    final selectedPath = controller.selectedPath;
    final selectedInCurrentTab = selectedPath != null &&
        currentPaths.any((path) => path.id == selectedPath.id);
    if (selectedPath != null && !selectedInCurrentTab) {
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
                        'Activity Path',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create guided learning paths with multiple text and image pages.',
                        style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading
                      ? null
                      : controller.loadActivityPaths,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Path'),
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
            _ActivityPathStatusTabs(
              selectedFilter: _statusFilter,
              activeCount: controller.countFor(ActivityPathStatusFilter.active),
              archivedCount:
                  controller.countFor(ActivityPathStatusFilter.archived),
              deletedCount:
                  controller.countFor(ActivityPathStatusFilter.deleted),
              onSelected: _selectStatusFilter,
            ),
            const SizedBox(height: 16),
            _ActivityPathListTools(
              searchController: _searchController,
              searchField: _searchField,
              sortOption: _sortOption,
              onSearchFieldChanged: (value) {
                setState(() {
                  _searchField = value;
                });
              },
              onSortChanged: (value) {
                setState(() {
                  _sortOption = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.isLoading && controller.activityPaths.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _ActivityPathTable(
                            paths: currentPaths,
                            statusFilter: _statusFilter,
                            selectedPathId: controller.selectedPathId,
                            onSelected: (path) =>
                                controller.selectPath(path.id),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          flex: 2,
                          child: _ActivityPathDetails(
                            controller: controller,
                            onEdit: _showEditDialog,
                            onArchive: (path) => path.isArchived
                                ? controller.unarchiveActivityPath(path.id)
                                : controller.archiveActivityPath(path.id),
                            onDelete: (path) =>
                                controller.deleteActivityPath(path.id),
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

  List<ActivityPath> _filteredPaths(List<ActivityPath> paths) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = paths.where((path) {
      if (query.isEmpty) {
        return true;
      }
      return _pathSearchValues(path, _searchField).any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();

    filtered.sort((left, right) {
      return switch (_sortOption) {
        _ActivityPathSortOption.newest => _compareDateDesc(left.createdAt, right.createdAt),
        _ActivityPathSortOption.oldest => _compareDateAsc(left.createdAt, right.createdAt),
        _ActivityPathSortOption.titleAsc => left.title.toLowerCase().compareTo(right.title.toLowerCase()),
        _ActivityPathSortOption.titleDesc => right.title.toLowerCase().compareTo(left.title.toLowerCase()),
        _ActivityPathSortOption.selectedDesc => right.selectedUserCount.compareTo(left.selectedUserCount),
        _ActivityPathSortOption.pageCountDesc => right.pages.length.compareTo(left.pages.length),
      };
    });

    return filtered;
  }

  List<String> _pathSearchValues(
    ActivityPath path,
    _ActivityPathSearchField field,
  ) {
    final pageValues = [
      for (final page in path.pages) ...[
        page.title ?? '',
        page.body,
      ],
    ];

    return switch (field) {
      _ActivityPathSearchField.all => [
          path.title,
          path.description ?? '',
          path.status,
          ...pageValues,
        ],
      _ActivityPathSearchField.title => [path.title],
      _ActivityPathSearchField.description => [path.description ?? ''],
      _ActivityPathSearchField.pageText => pageValues,
    };
  }
}

enum _ActivityPathSearchField {
  all('All fields'),
  title('Title'),
  description('Description'),
  pageText('Page text');

  const _ActivityPathSearchField(this.label);
  final String label;
}

enum _ActivityPathSortOption {
  newest('Newest created'),
  oldest('Oldest created'),
  titleAsc('Title A-Z'),
  titleDesc('Title Z-A'),
  selectedDesc('Most selected'),
  pageCountDesc('Most pages');

  const _ActivityPathSortOption(this.label);
  final String label;
}

class _ActivityPathListTools extends StatelessWidget {
  const _ActivityPathListTools({
    required this.searchController,
    required this.searchField,
    required this.sortOption,
    required this.onSearchFieldChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final _ActivityPathSearchField searchField;
  final _ActivityPathSortOption sortOption;
  final ValueChanged<_ActivityPathSearchField> onSearchFieldChanged;
  final ValueChanged<_ActivityPathSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search activity paths',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<_ActivityPathSearchField>(
            initialValue: searchField,
            decoration: const InputDecoration(
              labelText: 'Filter field',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final field in _ActivityPathSearchField.values)
                DropdownMenuItem(value: field, child: Text(field.label)),
            ],
            onChanged: (value) {
              if (value != null) {
                onSearchFieldChanged(value);
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<_ActivityPathSortOption>(
            initialValue: sortOption,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in _ActivityPathSortOption.values)
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

class _ActivityPathStatusTabs extends StatelessWidget {
  const _ActivityPathStatusTabs({
    required this.selectedFilter,
    required this.activeCount,
    required this.archivedCount,
    required this.deletedCount,
    required this.onSelected,
  });

  final ActivityPathStatusFilter selectedFilter;
  final int activeCount;
  final int archivedCount;
  final int deletedCount;
  final ValueChanged<ActivityPathStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ActivityPathStatusFilter>(
      segments: [
        ButtonSegment(
          value: ActivityPathStatusFilter.active,
          icon: const Icon(Icons.route_outlined),
          label: Text('Active ($activeCount)'),
        ),
        ButtonSegment(
          value: ActivityPathStatusFilter.archived,
          icon: const Icon(Icons.archive_outlined),
          label: Text('Archived ($archivedCount)'),
        ),
        ButtonSegment(
          value: ActivityPathStatusFilter.deleted,
          icon: const Icon(Icons.delete_outline),
          label: Text('Deleted ($deletedCount)'),
        ),
      ],
      selected: {selectedFilter},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _ActivityPathTable extends StatelessWidget {
  const _ActivityPathTable({
    required this.paths,
    required this.statusFilter,
    required this.selectedPathId,
    required this.onSelected,
  });

  final List<ActivityPath> paths;
  final ActivityPathStatusFilter statusFilter;
  final String? selectedPathId;
  final ValueChanged<ActivityPath> onSelected;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) {
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
                  columnSpacing: 18,
                  horizontalMargin: 12,
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
                    DataColumn(label: Text('Selected')),
                    DataColumn(label: Text('Pages')),
                    DataColumn(label: Text('Created')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final path in paths)
                      DataRow(
                        selected: path.id == selectedPathId,
                        onSelectChanged: (_) => onSelected(path),
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 170,
                              child: Text(
                                path.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(path.selectedUserCount.toString())),
                          DataCell(Text(path.pages.length.toString())),
                          DataCell(Text(_formatDate(path.createdAt))),
                          DataCell(_StatusChip(label: path.status)),
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
      ActivityPathStatusFilter.active => 'No active activity paths found.',
      ActivityPathStatusFilter.archived => 'No archived activity paths found.',
      ActivityPathStatusFilter.deleted => 'No deleted activity paths found.',
    };
  }
}

class _ActivityPathDetails extends StatelessWidget {
  const _ActivityPathDetails({
    required this.controller,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final ActivityPathsController controller;
  final ValueChanged<ActivityPath> onEdit;
  final ValueChanged<ActivityPath> onArchive;
  final ValueChanged<ActivityPath> onDelete;

  @override
  Widget build(BuildContext context) {
    final path = controller.selectedPath;
    if (path == null) {
      return const Card(
        elevation: 0,
        color: Colors.white,
        child: Center(child: Text('Select an activity path.')),
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
            path.title,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${path.selectedUserCount} users selected this path',
            style: const TextStyle(color: Color(0xFF66736F)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              TextButton.icon(
                onPressed: path.isDeleted ? null : () => onEdit(path),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: path.isDeleted ? null : () => onArchive(path),
                icon: Icon(
                  path.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                label: Text(path.isArchived ? 'Unarchive' : 'Archive'),
              ),
              TextButton.icon(
                onPressed: path.isDeleted ? null : () => onDelete(path),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
            ],
          ),
          if (path.description?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            Text(path.description!),
          ],
          const SizedBox(height: 20),
          const Text(
            'Pages',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (path.pages.isEmpty)
            const _EmptyPanel(text: 'No pages added.')
          else
            for (final page in path.pages) _PathPagePanel(page: page),
        ],
      ),
    );
  }
}

class _PathPagePanel extends StatelessWidget {
  const _PathPagePanel({required this.page});

  final ActivityPathPage page;

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
          Text(
            'Page ${page.pageNumber}${page.title?.isNotEmpty == true ? ': ${page.title}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(page.body, style: const TextStyle(color: Color(0xFF66736F))),
          if (page.images.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final image in page.images)
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child: SizedBox(
                      width: 76,
                      height: 76,
                      child: Image.network(image.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityPathFormDialog extends StatefulWidget {
  const _ActivityPathFormDialog({
    required this.controller,
    this.activityPath,
  });

  final ActivityPathsController controller;
  final ActivityPath? activityPath;

  @override
  State<_ActivityPathFormDialog> createState() =>
      _ActivityPathFormDialogState();
}

class _ActivityPathFormDialogState extends State<_ActivityPathFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_PageEditorState> _pages = [];

  bool get _isEditing => widget.activityPath != null;

  @override
  void initState() {
    super.initState();
    final path = widget.activityPath;
    if (path == null) {
      _pages.add(_PageEditorState());
      return;
    }

    _titleController.text = path.title;
    _descriptionController.text = path.description ?? '';
    _pages.addAll([
      for (final page in path.pages)
        _PageEditorState(
          title: page.title ?? '',
          body: page.body,
          images: [
            for (final image in page.images)
              _PickedPathImage(existingUrl: image.imageUrl),
          ],
        ),
    ]);
    if (_pages.isEmpty) {
      _pages.add(_PageEditorState());
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages(_PageEditorState page) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    if (result == null) {
      return;
    }

    setState(() {
      page.images.addAll([
        for (final file in result.files)
          if (file.bytes != null)
            _PickedPathImage(
              bytes: file.bytes,
              fileName: file.name,
              mimeType: _mimeTypeFor(file.extension),
            ),
      ]);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showSnack('Sign in again before saving an activity path.');
      return;
    }

    final draft = ActivityPathDraft(
      title: _titleController.text,
      description: _descriptionController.text,
      createdBy: userId,
      pages: [
        for (final page in _pages)
          ActivityPathPageDraft(
            title: page.titleController.text,
            body: page.bodyController.text,
            images: [
              for (final image in page.images)
                ActivityPathImageDraft(
                  imageUrl: image.existingUrl,
                  imageBytes: image.bytes,
                  imageFileName: image.fileName,
                  imageMimeType: image.mimeType,
                ),
            ],
          ),
      ],
    );

    final path = widget.activityPath;
    final success = path == null
        ? await widget.controller.createActivityPath(draft)
        : await widget.controller.updateActivityPath(
            activityPathId: path.id,
            input: draft,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _addPage() {
    setState(() {
      _pages.add(_PageEditorState());
    });
  }

  void _removePage(int index) {
    if (_pages.length == 1) {
      _showSnack('Activity path must have at least one page.');
      return;
    }
    setState(() {
      _pages.removeAt(index).dispose();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 840),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Activity Path' : 'Create Activity Path',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build a guided path with multiple pages, text, and images.',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _PathMetadataPanel(
                        titleController: _titleController,
                        descriptionController: _descriptionController,
                        validator: _required,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F2),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          border: Border.all(color: const Color(0xFFE8ECEA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.library_books_outlined,
                              color: Color(0xFF1F7A64),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_pages.length} pages',
                                style: const TextStyle(
                                  color: Color(0xFF17201D),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _addPage,
                              icon: const Icon(Icons.add),
                              label: const Text('Add Page'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      for (var index = 0; index < _pages.length; index += 1)
                        _PageEditor(
                          key: ValueKey(_pages[index]),
                          pageNumber: index + 1,
                          page: _pages[index],
                          onPickImages: () => _pickImages(_pages[index]),
                          onRemovePage: () => _removePage(index),
                          onRemoveImage: (image) {
                            setState(() {
                              _pages[index].images.remove(image);
                            });
                          },
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

class _PathMetadataPanel extends StatelessWidget {
  const _PathMetadataPanel({
    required this.titleController,
    required this.descriptionController,
    required this.validator,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Path title',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              validator: validator,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
              ),
              minLines: 2,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _PageEditor extends StatelessWidget {
  const _PageEditor({
    super.key,
    required this.pageNumber,
    required this.page,
    required this.onPickImages,
    required this.onRemovePage,
    required this.onRemoveImage,
  });

  final int pageNumber;
  final _PageEditorState page;
  final VoidCallback onPickImages;
  final VoidCallback onRemovePage;
  final ValueChanged<_PickedPathImage> onRemoveImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECEA),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 680),
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            border: Border.all(color: const Color(0xFFDDE4E1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFF14211D),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    child: Text(
                      pageNumber.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: page.titleController,
                      decoration: const InputDecoration(
                        labelText: 'Page title',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemovePage,
                    tooltip: 'Remove page',
                    color: Theme.of(context).colorScheme.error,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: page.bodyController,
                decoration: const InputDecoration(
                  labelText: 'Page text',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 8,
                maxLines: 12,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
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
                        const Expanded(
                          child: Text(
                            'Images',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onPickImages,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Add Images'),
                        ),
                      ],
                    ),
                    if (page.images.isEmpty) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'No images added to this page.',
                        style: TextStyle(color: Color(0xFF66736F)),
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final image in page.images)
                            _PickedImageChip(
                              image: image,
                              onRemove: () => onRemoveImage(image),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedImageChip extends StatelessWidget {
  const _PickedImageChip({
    required this.image,
    required this.onRemove,
  });

  final _PickedPathImage image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: SizedBox(
              width: 46,
              height: 46,
              child: image.bytes != null
                  ? Image.memory(image.bytes!, fit: BoxFit.cover)
                  : Image.network(image.existingUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              image.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove image',
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }
}

class _PageEditorState {
  _PageEditorState({
    String title = '',
    String body = '',
    List<_PickedPathImage> images = const [],
  })  : titleController = TextEditingController(text: title),
        bodyController = TextEditingController(text: body),
        images = [...images];

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final List<_PickedPathImage> images;

  void dispose() {
    titleController.dispose();
    bodyController.dispose();
  }
}

class _PickedPathImage {
  const _PickedPathImage({
    this.existingUrl,
    this.bytes,
    this.fileName,
    this.mimeType,
  });

  final String? existingUrl;
  final Uint8List? bytes;
  final String? fileName;
  final String? mimeType;

  String get label {
    final name = fileName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Existing image';
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
