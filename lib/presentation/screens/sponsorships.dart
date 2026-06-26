import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/community_activities_controller.dart';
import '../../models/community_activity.dart';

enum SponsorshipStatusFilter {
  active,
  archived,
  deleted,
}

class SponsorshipsPage extends StatefulWidget {
  SponsorshipsPage({
    super.key,
    CommunityActivitiesController? controller,
  }) : controller = controller ?? CommunityActivitiesController();

  final CommunityActivitiesController controller;

  @override
  State<SponsorshipsPage> createState() => _SponsorshipsPageState();
}

class _SponsorshipsPageState extends State<SponsorshipsPage> {
  SponsorshipStatusFilter _statusFilter = SponsorshipStatusFilter.active;

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

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SponsorshipFormDialog(controller: widget.controller),
    );
  }

  void _selectStatusFilter(SponsorshipStatusFilter filter) {
    setState(() {
      _statusFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final activityTitlesById = {
      for (final activity in controller.activities) activity.id: activity.title,
    };
    final sponsorships = [
      for (final sponsorship in controller.sponsorships)
        if (_matchesStatus(sponsorship))
          _SponsorshipHistoryItem(
            activityTitle: activityTitlesById[sponsorship.activityId],
            sponsorship: sponsorship,
          ),
    ];

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
                        'Sponsorships',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Review sponsorship and product history across activities.',
                        style: TextStyle(color: Color(0xFF66736F), fontSize: 15),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: controller.isLoading ? null : controller.loadActivities,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: controller.isSaving ? null : _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Sponsorship'),
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
            _SponsorshipStatusTabs(
              selectedFilter: _statusFilter,
              activeCount: _countFor(
                controller.sponsorships,
                SponsorshipStatusFilter.active,
              ),
              archivedCount: _countFor(
                controller.sponsorships,
                SponsorshipStatusFilter.archived,
              ),
              deletedCount: _countFor(
                controller.sponsorships,
                SponsorshipStatusFilter.deleted,
              ),
              onSelected: _selectStatusFilter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: controller.isLoading && sponsorships.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : sponsorships.isEmpty
                      ? Card(
                          elevation: 0,
                          color: Colors.white,
                          child: Center(child: Text(_emptyMessage)),
                        )
                      : ListView.separated(
                          itemCount: sponsorships.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = sponsorships[index];
                            return _SponsorshipHistoryCard(
                              item: item,
                              archiveLabel: item.sponsorship.isArchived
                                  ? 'Unarchive'
                                  : 'Archive',
                              onArchive: item.sponsorship.isDeleted
                                  ? null
                                  : item.sponsorship.isArchived
                                      ? () => controller.unarchiveSponsorship(
                                            item.sponsorship.id,
                                          )
                                      : () => controller.archiveSponsorship(
                                            item.sponsorship.id,
                                          ),
                              onDelete: item.sponsorship.isDeleted
                                  ? null
                                  : () => controller.deleteSponsorship(
                                        item.sponsorship.id,
                                      ),
                              onArchiveProduct: controller.archiveProduct,
                              onDeleteProduct: controller.deleteProduct,
                              onEditProduct: ({
                                required sponsorship,
                                required product,
                              }) =>
                                  _showEditProductDialog(
                                sponsorship: sponsorship,
                                product: product,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProductDialog({
    required ActivitySponsorship sponsorship,
    required SponsorshipProduct product,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ProductEditDialog(
        controller: widget.controller,
        sponsorship: sponsorship,
        product: product,
      ),
    );
  }

  bool _matchesStatus(ActivitySponsorship sponsorship) {
    return switch (_statusFilter) {
      SponsorshipStatusFilter.active =>
        !sponsorship.isDeleted && !sponsorship.isArchived,
      SponsorshipStatusFilter.archived =>
        sponsorship.isArchived && !sponsorship.isDeleted,
      SponsorshipStatusFilter.deleted => sponsorship.isDeleted,
    };
  }

  int _countFor(
    List<ActivitySponsorship> sponsorships,
    SponsorshipStatusFilter filter,
  ) {
    return sponsorships.where((sponsorship) {
      return switch (filter) {
        SponsorshipStatusFilter.active =>
          !sponsorship.isDeleted && !sponsorship.isArchived,
        SponsorshipStatusFilter.archived =>
          sponsorship.isArchived && !sponsorship.isDeleted,
        SponsorshipStatusFilter.deleted => sponsorship.isDeleted,
      };
    }).length;
  }

  String get _emptyMessage {
    return switch (_statusFilter) {
      SponsorshipStatusFilter.active => 'No active sponsorships found.',
      SponsorshipStatusFilter.archived => 'No archived sponsorships found.',
      SponsorshipStatusFilter.deleted => 'No deleted sponsorships found.',
    };
  }
}

class _SponsorshipStatusTabs extends StatelessWidget {
  const _SponsorshipStatusTabs({
    required this.selectedFilter,
    required this.activeCount,
    required this.archivedCount,
    required this.deletedCount,
    required this.onSelected,
  });

  final SponsorshipStatusFilter selectedFilter;
  final int activeCount;
  final int archivedCount;
  final int deletedCount;
  final ValueChanged<SponsorshipStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<SponsorshipStatusFilter>(
      segments: [
        ButtonSegment(
          value: SponsorshipStatusFilter.active,
          icon: const Icon(Icons.volunteer_activism_outlined),
          label: Text('Active ($activeCount)'),
        ),
        ButtonSegment(
          value: SponsorshipStatusFilter.archived,
          icon: const Icon(Icons.archive_outlined),
          label: Text('Archived ($archivedCount)'),
        ),
        ButtonSegment(
          value: SponsorshipStatusFilter.deleted,
          icon: const Icon(Icons.delete_outline),
          label: Text('Deleted ($deletedCount)'),
        ),
      ],
      selected: {selectedFilter},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

class _SponsorshipHistoryItem {
  const _SponsorshipHistoryItem({
    required this.sponsorship,
    this.activityTitle,
  });

  final String? activityTitle;
  final ActivitySponsorship sponsorship;
}

class _SponsorshipHistoryCard extends StatelessWidget {
  const _SponsorshipHistoryCard({
    required this.item,
    required this.archiveLabel,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveProduct,
    required this.onDeleteProduct,
    required this.onEditProduct,
  });

  final _SponsorshipHistoryItem item;
  final String archiveLabel;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final ValueChanged<String> onArchiveProduct;
  final ValueChanged<String> onDeleteProduct;
  final void Function({
    required ActivitySponsorship sponsorship,
    required SponsorshipProduct product,
  }) onEditProduct;

  @override
  Widget build(BuildContext context) {
    final sponsorship = item.sponsorship;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sponsorship.sponsorName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17201D),
                    ),
                  ),
                ),
                _StatusChip(label: sponsorship.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.activityTitle ?? 'Available for activity assignment',
              style: const TextStyle(color: Color(0xFF66736F)),
            ),
            if ((sponsorship.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sponsorship.description!),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onArchive,
                  icon: Icon(
                    sponsorship.isArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  label: Text(archiveLabel),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final product in sponsorship.products)
                  _ProductHistoryTile(
                    product: product,
                    onEdit: product.isDeleted
                        ? null
                        : () => onEditProduct(
                              sponsorship: sponsorship,
                              product: product,
                            ),
                    onArchive: product.isArchived || product.isDeleted
                        ? null
                        : () => onArchiveProduct(product.id),
                    onDelete: product.isDeleted
                        ? null
                        : () => onDeleteProduct(product.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorshipFormDialog extends StatefulWidget {
  const _SponsorshipFormDialog({required this.controller});

  final CommunityActivitiesController controller;

  @override
  State<_SponsorshipFormDialog> createState() => _SponsorshipFormDialogState();
}

class _SponsorshipFormDialogState extends State<_SponsorshipFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _sponsorNameController = TextEditingController();
  final _sponsorDescriptionController = TextEditingController();
  final List<_ProductDraftControllers> _products = [_ProductDraftControllers()];

  @override
  void dispose() {
    _sponsorNameController.dispose();
    _sponsorDescriptionController.dispose();
    for (final product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.createSponsorship(
      sponsorship: SponsorshipDraft(
        sponsorName: _sponsorNameController.text.trim(),
        description: _blankToNull(_sponsorDescriptionController.text),
        products: [
          for (final product in _products)
            if (product.name.text.trim().isNotEmpty)
              SponsorshipProductDraft(
                name: product.name.text.trim(),
                description: _blankToNull(product.description.text),
                imageBytes: product.imageBytes,
                imageFileName: product.imageFileName,
                imageMimeType: product.imageMimeType,
              ),
        ],
      ),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Sponsorship',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _sponsorNameController,
                        decoration: const InputDecoration(
                          labelText: 'Sponsor name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sponsorDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Sponsor description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Products',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _products.add(_ProductDraftControllers());
                              });
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                          ),
                        ],
                      ),
                      for (var index = 0; index < _products.length; index++)
                        _ProductDraftFields(
                          product: _products[index],
                          onRemove: _products.length == 1
                              ? null
                              : () {
                                  setState(() {
                                    _products.removeAt(index).dispose();
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
                      label: const Text('Add Sponsorship'),
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
}

class _ProductDraftControllers {
  final name = TextEditingController();
  final description = TextEditingController();
  Uint8List? imageBytes;
  String? imageFileName;
  String? imageMimeType;

  void dispose() {
    name.dispose();
    description.dispose();
  }
}

class _ProductDraftFields extends StatefulWidget {
  const _ProductDraftFields({
    required this.product,
    required this.onRemove,
  });

  final _ProductDraftControllers product;
  final VoidCallback? onRemove;

  @override
  State<_ProductDraftFields> createState() => _ProductDraftFieldsState();
}

class _ProductDraftFieldsState extends State<_ProductDraftFields> {
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null) {
        return;
      }
      if (bytes == null) {
        _showPickerError('Unable to read the selected image.');
        return;
      }

      setState(() {
        widget.product.imageBytes = bytes;
        widget.product.imageFileName = file.name;
        widget.product.imageMimeType = _mimeTypeFor(file.extension);
      });
    } on PlatformException catch (error) {
      _showPickerError(error.message ?? 'Unable to open image picker.');
    } catch (_) {
      _showPickerError('Unable to open image picker.');
    }
  }

  void _showPickerError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mimeTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE8ECEA)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.product.name,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onRemove,
                tooltip: 'Remove product',
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.product.description,
            decoration: const InputDecoration(
              labelText: 'Product description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(
                    widget.product.imageFileName ?? 'Select product image',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.product.imageBytes != null) ...[
                const SizedBox(width: 10),
                const Icon(Icons.check_circle, color: Color(0xFF1F7A64)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductHistoryTile extends StatelessWidget {
  const _ProductHistoryTile({
    required this.product,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final SponsorshipProduct product;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return SizedBox(
      width: 260,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7F8),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: imageUrl == null || imageUrl.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE8ECEA),
                          child: Icon(Icons.image_outlined),
                        )
                      : Image.network(imageUrl, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              _StatusChip(label: product.status),
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit product',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    onPressed: onArchive,
                    tooltip: 'Archive product',
                    icon: const Icon(Icons.archive_outlined),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Delete product',
                    icon: const Icon(Icons.delete_outline),
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

class _ProductEditDialog extends StatefulWidget {
  const _ProductEditDialog({
    required this.controller,
    required this.sponsorship,
    required this.product,
  });

  final CommunityActivitiesController controller;
  final ActivitySponsorship sponsorship;
  final SponsorshipProduct product;

  @override
  State<_ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<_ProductEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _imageMimeType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(
      text: widget.product.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      final bytes = file?.bytes;
      if (file == null) {
        return;
      }
      if (bytes == null) {
        _showPickerError('Unable to read the selected image.');
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _imageFileName = file.name;
        _imageMimeType = _mimeTypeFor(file.extension);
      });
    } on PlatformException catch (error) {
      _showPickerError(error.message ?? 'Unable to open image picker.');
    } catch (_) {
      _showPickerError('Unable to open image picker.');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.updateProduct(
      productId: widget.product.id,
      sponsorshipId: widget.sponsorship.id,
      input: UpdateSponsorshipProductInput(
        name: _nameController.text.trim(),
        description: _blankToNull(_descriptionController.text),
        imageUrl: widget.product.imageUrl,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
        imageMimeType: _imageMimeType,
      ),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _showPickerError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _mimeTypeFor(String? extension) {
    return switch (extension?.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Product description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.folder_open_outlined),
                label: Text(
                  _imageFileName ?? 'Replace product image',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: widget.controller.isSaving ? null : _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
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
