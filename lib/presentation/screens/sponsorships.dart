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
  final _searchController = TextEditingController();
  SponsorshipStatusFilter _statusFilter = SponsorshipStatusFilter.active;
  _SponsorshipSearchField _searchField = _SponsorshipSearchField.all;
  _SponsorshipSortOption _sortOption = _SponsorshipSortOption.newest;
  String? _selectedSponsorshipId;

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

  Future<void> _showCreateDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SponsorshipFormDialog(controller: widget.controller),
    );
  }

  void _selectStatusFilter(SponsorshipStatusFilter filter) {
    setState(() {
      _statusFilter = filter;
      _selectedSponsorshipId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final activityTitlesById = {
      for (final activity in controller.activities) activity.id: activity.title,
    };
    final sponsorships = _filteredSponsorships([
      for (final sponsorship in controller.sponsorships)
        if (_matchesStatus(sponsorship))
          _SponsorshipHistoryItem(
            activityTitle: _activityTitleSummary(
              sponsorship.activityIds,
              activityTitlesById,
            ),
            sponsorship: sponsorship,
          ),
    ]);
    final selectedItem = _selectedSponsorshipItem(sponsorships);

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
            _SponsorshipListTools(
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
              child: controller.isLoading && sponsorships.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : sponsorships.isEmpty
                      ? Card(
                          elevation: 0,
                          color: Colors.white,
                          child: Center(child: Text(_emptyMessage)),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _SponsorshipsTable(
                                items: sponsorships,
                                selectedSponsorshipId: _selectedSponsorshipId,
                                onSelected: (item) {
                                  setState(() {
                                    _selectedSponsorshipId =
                                        item.sponsorship.id;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              flex: 2,
                              child: selectedItem == null
                                  ? const Card(
                                      elevation: 0,
                                      color: Colors.white,
                                      child: Center(
                                        child: Text('Select a sponsorship.'),
                                      ),
                                    )
                                  : _SponsorshipHistoryCard(
                                      item: selectedItem,
                                      onEdit: selectedItem.sponsorship.isDeleted
                                          ? null
                                          : () => _showEditSponsorshipDialog(
                                                selectedItem.sponsorship,
                                              ),
                                      archiveLabel:
                                          selectedItem.sponsorship.isArchived
                                              ? 'Unarchive'
                                              : 'Archive',
                                      onArchive:
                                          selectedItem.sponsorship.isDeleted
                                              ? null
                                              : selectedItem
                                                      .sponsorship.isArchived
                                                  ? () => controller
                                                      .unarchiveSponsorship(
                                                        selectedItem
                                                            .sponsorship.id,
                                                      )
                                                  : () => controller
                                                      .archiveSponsorship(
                                                        selectedItem
                                                            .sponsorship.id,
                                                      ),
                                      onDelete:
                                          selectedItem.sponsorship.isDeleted
                                              ? null
                                              : () => controller
                                                  .deleteSponsorship(
                                                    selectedItem.sponsorship.id,
                                                  ),
                                      onArchiveProduct:
                                          controller.archiveProduct,
                                      onUnarchiveProduct:
                                          controller.unarchiveProduct,
                                      onDeleteProduct: controller.deleteProduct,
                                      onEditProduct: ({
                                        required sponsorship,
                                        required product,
                                      }) =>
                                          _showEditProductDialog(
                                        sponsorship: sponsorship,
                                        product: product,
                                      ),
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

  Future<void> _showEditSponsorshipDialog(
    ActivitySponsorship sponsorship,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SponsorshipEditDialog(
        controller: widget.controller,
        sponsorship: sponsorship,
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

  List<_SponsorshipHistoryItem> _filteredSponsorships(
    List<_SponsorshipHistoryItem> items,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = items.where((item) {
      if (query.isEmpty) {
        return true;
      }
      return _sponsorshipSearchValues(item, _searchField).any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();

    filtered.sort((left, right) {
      final leftSponsorship = left.sponsorship;
      final rightSponsorship = right.sponsorship;
      return switch (_sortOption) {
        _SponsorshipSortOption.newest => _compareDateDesc(
            leftSponsorship.createdAt,
            rightSponsorship.createdAt,
          ),
        _SponsorshipSortOption.oldest => _compareDateAsc(
            leftSponsorship.createdAt,
            rightSponsorship.createdAt,
          ),
        _SponsorshipSortOption.sponsorAsc => leftSponsorship.sponsorName
            .toLowerCase()
            .compareTo(rightSponsorship.sponsorName.toLowerCase()),
        _SponsorshipSortOption.sponsorDesc => rightSponsorship.sponsorName
            .toLowerCase()
            .compareTo(leftSponsorship.sponsorName.toLowerCase()),
        _SponsorshipSortOption.activityAsc => (left.activityTitle ?? '')
            .toLowerCase()
            .compareTo((right.activityTitle ?? '').toLowerCase()),
        _SponsorshipSortOption.productCountDesc => rightSponsorship
            .activeProductCount
            .compareTo(leftSponsorship.activeProductCount),
      };
    });

    return filtered;
  }

  String? _activityTitleSummary(
    List<String> activityIds,
    Map<String, String> activityTitlesById,
  ) {
    if (activityIds.isEmpty) {
      return null;
    }

    final titles = [
      for (final activityId in activityIds)
        if (activityTitlesById[activityId] case final String title) title,
    ];
    if (titles.isEmpty) {
      return '${activityIds.length} assigned activities';
    }
    if (titles.length <= 2) {
      return titles.join(', ');
    }
    return '${titles.take(2).join(', ')} +${titles.length - 2} more';
  }

  _SponsorshipHistoryItem? _selectedSponsorshipItem(
    List<_SponsorshipHistoryItem> items,
  ) {
    final selectedId = _selectedSponsorshipId;
    if (selectedId == null) {
      return null;
    }
    for (final item in items) {
      if (item.sponsorship.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  List<String> _sponsorshipSearchValues(
    _SponsorshipHistoryItem item,
    _SponsorshipSearchField field,
  ) {
    final sponsorship = item.sponsorship;
    final productValues = [
      for (final product in sponsorship.products) ...[
        product.name,
        product.description ?? '',
        product.status,
      ],
    ];

    return switch (field) {
      _SponsorshipSearchField.all => [
          sponsorship.sponsorName,
          sponsorship.description ?? '',
          item.activityTitle ?? '',
          sponsorship.status,
          ...productValues,
        ],
      _SponsorshipSearchField.sponsor => [sponsorship.sponsorName],
      _SponsorshipSearchField.description => [sponsorship.description ?? ''],
      _SponsorshipSearchField.activity => [item.activityTitle ?? ''],
      _SponsorshipSearchField.product => productValues,
    };
  }
}

enum _SponsorshipSearchField {
  all('All fields'),
  sponsor('Sponsor'),
  description('Description'),
  activity('Activity'),
  product('Products');

  const _SponsorshipSearchField(this.label);
  final String label;
}

enum _SponsorshipSortOption {
  newest('Newest created'),
  oldest('Oldest created'),
  sponsorAsc('Sponsor A-Z'),
  sponsorDesc('Sponsor Z-A'),
  activityAsc('Activity A-Z'),
  productCountDesc('Most products');

  const _SponsorshipSortOption(this.label);
  final String label;
}

class _SponsorshipListTools extends StatelessWidget {
  const _SponsorshipListTools({
    required this.searchController,
    required this.searchField,
    required this.sortOption,
    required this.onSearchFieldChanged,
    required this.onSortChanged,
  });

  final TextEditingController searchController;
  final _SponsorshipSearchField searchField;
  final _SponsorshipSortOption sortOption;
  final ValueChanged<_SponsorshipSearchField> onSearchFieldChanged;
  final ValueChanged<_SponsorshipSortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Search sponsorships',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<_SponsorshipSearchField>(
            initialValue: searchField,
            decoration: const InputDecoration(
              labelText: 'Filter field',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final field in _SponsorshipSearchField.values)
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
          child: DropdownButtonFormField<_SponsorshipSortOption>(
            initialValue: sortOption,
            decoration: const InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final option in _SponsorshipSortOption.values)
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

class _SponsorshipsTable extends StatefulWidget {
  const _SponsorshipsTable({
    required this.items,
    required this.selectedSponsorshipId,
    required this.onSelected,
  });

  final List<_SponsorshipHistoryItem> items;
  final String? selectedSponsorshipId;
  final ValueChanged<_SponsorshipHistoryItem> onSelected;

  @override
  State<_SponsorshipsTable> createState() => _SponsorshipsTableState();
}

class _SponsorshipsTableState extends State<_SponsorshipsTable> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: SingleChildScrollView(
                  controller: _verticalController,
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
                      DataColumn(label: Text('Sponsor')),
                      DataColumn(label: Text('Activity')),
                      DataColumn(label: Text('Products')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Created')),
                    ],
                    rows: [
                      for (final item in widget.items)
                        DataRow(
                          selected: item.sponsorship.id ==
                              widget.selectedSponsorshipId,
                          onSelectChanged: (_) => widget.onSelected(item),
                          cells: [
                            DataCell(
                              SizedBox(
                                width: 150,
                                child: Text(
                                  item.sponsorship.sponsorName,
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
                                width: 150,
                                child: Text(
                                  item.activityTitle ??
                                      'Available for assignment',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${item.sponsorship.activeProductCount} active',
                              ),
                            ),
                            DataCell(
                              _StatusChip(label: item.sponsorship.status),
                            ),
                            DataCell(
                              Text(_formatDate(item.sponsorship.createdAt)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SponsorshipHistoryCard extends StatelessWidget {
  const _SponsorshipHistoryCard({
    required this.item,
    required this.onEdit,
    required this.archiveLabel,
    required this.onArchive,
    required this.onDelete,
    required this.onArchiveProduct,
    required this.onUnarchiveProduct,
    required this.onDeleteProduct,
    required this.onEditProduct,
  });

  final _SponsorshipHistoryItem item;
  final VoidCallback? onEdit;
  final String archiveLabel;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final ValueChanged<String> onArchiveProduct;
  final ValueChanged<String> onUnarchiveProduct;
  final ValueChanged<String> onDeleteProduct;
  final void Function({
    required ActivitySponsorship sponsorship,
    required SponsorshipProduct product,
  }) onEditProduct;

  @override
  Widget build(BuildContext context) {
    final sponsorship = item.sponsorship;
    final activeProducts = sponsorship.products
        .where((product) => !product.isDeleted && !product.isArchived)
        .toList();
    final archivedProducts = sponsorship.products
        .where((product) => !product.isDeleted && product.isArchived)
        .toList();
    final deletedProducts = sponsorship.products
        .where((product) => product.isDeleted)
        .toList();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
            _SponsorshipSummaryPanel(
              sponsorship: sponsorship,
              activityTitle: item.activityTitle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
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
            _ProductsSectionHeader(
              title: 'Active products',
              count: activeProducts.length,
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 10),
            if (activeProducts.isEmpty)
              const Text(
                'No active products.',
                style: TextStyle(
                  color: Color(0xFF66736F),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final product in activeProducts)
                    _buildProductTile(
                      sponsorship: sponsorship,
                      product: product,
                    ),
                ],
              ),
            if (archivedProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProductHistorySection(
                title: 'Archived products',
                icon: Icons.archive_outlined,
                products: archivedProducts,
                tileFor: (product) => _buildProductTile(
                  sponsorship: sponsorship,
                  product: product,
                ),
              ),
            ],
            if (deletedProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ProductHistorySection(
                title: 'Deleted products',
                icon: Icons.delete_outline,
                products: deletedProducts,
                tileFor: (product) => _buildProductTile(
                  sponsorship: sponsorship,
                  product: product,
                ),
              ),
            ],
        ],
      ),
    );
  }

  Widget _buildProductTile({
    required ActivitySponsorship sponsorship,
    required SponsorshipProduct product,
  }) {
    return _ProductHistoryTile(
      product: product,
      onEdit: product.isDeleted
          ? null
          : () => onEditProduct(
                sponsorship: sponsorship,
                product: product,
              ),
      archiveTooltip: product.isArchived ? 'Unarchive product' : 'Archive product',
      archiveIcon:
          product.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
      onArchive: product.isDeleted
          ? null
          : product.isArchived
              ? () => onUnarchiveProduct(product.id)
              : () => onArchiveProduct(product.id),
      onDelete: product.isDeleted ? null : () => onDeleteProduct(product.id),
    );
  }
}

class _ProductHistorySection extends StatelessWidget {
  const _ProductHistorySection({
    required this.title,
    required this.icon,
    required this.products,
    required this.tileFor,
  });

  final String title;
  final IconData icon;
  final List<SponsorshipProduct> products;
  final Widget Function(SponsorshipProduct product) tileFor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        border: Border.all(color: const Color(0xFFE8ECEA)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(icon, color: const Color(0xFF66736F)),
        title: Text(
          '$title (${products.length})',
          style: const TextStyle(
            color: Color(0xFF3A4541),
            fontWeight: FontWeight.w800,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final product in products) tileFor(product),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SponsorshipSummaryPanel extends StatelessWidget {
  const _SponsorshipSummaryPanel({
    required this.sponsorship,
    required this.activityTitle,
  });

  final ActivitySponsorship sponsorship;
  final String? activityTitle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFBFE8D8),
                child: Icon(
                  Icons.volunteer_activism_outlined,
                  color: Color(0xFF14211D),
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 14),
          _SponsorshipDetailRow(
            label: 'Assigned activities',
            value: activityTitle ?? 'Available for activity assignment',
          ),
          _SponsorshipDetailRow(
            label: 'Active products',
            value: sponsorship.activeProductCount.toString(),
          ),
          _SponsorshipDetailRow(
            label: 'Archived products',
            value: sponsorship.archivedProductCount.toString(),
          ),
          _SponsorshipDetailRow(
            label: 'Deleted products',
            value: sponsorship.deletedProductCount.toString(),
          ),
          _SponsorshipDetailRow(
            label: 'Created on',
            value: _formatDate(sponsorship.createdAt),
          ),
          _SponsorshipDetailRow(
            label: 'Description',
            value: sponsorship.description,
          ),
        ],
      ),
    );
  }
}

class _SponsorshipDetailRow extends StatelessWidget {
  const _SponsorshipDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final displayValue = value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
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

class _ProductsSectionHeader extends StatelessWidget {
  const _ProductsSectionHeader({
    required this.title,
    required this.count,
    required this.icon,
  });

  final String title;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1F7A64), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$title ($count)',
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
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
                const SizedBox(height: 4),
                const Text(
                  'Create a reusable sponsor profile and add the products it can provide.',
                  style: TextStyle(color: Color(0xFF66736F)),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _SponsorshipFormSection(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Sponsor Details',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sponsorNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Required.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _sponsorDescriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor description',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProductsHeader(
                        count: _products.length,
                        onAdd: () {
                          setState(() {
                            _products.add(_ProductDraftControllers());
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      for (var index = 0; index < _products.length; index++)
                        _ProductDraftFields(
                          index: index + 1,
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

class _SponsorshipEditDialog extends StatefulWidget {
  const _SponsorshipEditDialog({
    required this.controller,
    required this.sponsorship,
  });

  final CommunityActivitiesController controller;
  final ActivitySponsorship sponsorship;

  @override
  State<_SponsorshipEditDialog> createState() => _SponsorshipEditDialogState();
}

class _SponsorshipEditDialogState extends State<_SponsorshipEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sponsorNameController;
  late final TextEditingController _sponsorDescriptionController;
  final List<_ProductDraftControllers> _newProducts = [];

  @override
  void initState() {
    super.initState();
    _sponsorNameController = TextEditingController(
      text: widget.sponsorship.sponsorName,
    );
    _sponsorDescriptionController = TextEditingController(
      text: widget.sponsorship.description ?? '',
    );
  }

  @override
  void dispose() {
    _sponsorNameController.dispose();
    _sponsorDescriptionController.dispose();
    for (final product in _newProducts) {
      product.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.controller.updateSponsorship(
      sponsorshipId: widget.sponsorship.id,
      sponsorship: SponsorshipDraft(
        sponsorName: _sponsorNameController.text.trim(),
        description: _blankToNull(_sponsorDescriptionController.text),
        products: [
          for (final product in _newProducts)
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
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Sponsorship',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Update sponsor details and add new products without changing existing product history.',
                  style: TextStyle(color: Color(0xFF66736F)),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      _SponsorshipFormSection(
                        icon: Icons.volunteer_activism_outlined,
                        title: 'Sponsor Details',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sponsorNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Required.';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _sponsorDescriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Sponsor description',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                minLines: 2,
                                maxLines: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ProductsHeader(
                        count: _newProducts.length,
                        onAdd: () {
                          setState(() {
                            _newProducts.add(_ProductDraftControllers());
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_newProducts.isEmpty)
                        const _EmptyPanel(text: 'No new products added.')
                      else
                        for (var index = 0;
                            index < _newProducts.length;
                            index++)
                          _ProductDraftFields(
                            index: index + 1,
                            product: _newProducts[index],
                            onRemove: () {
                              setState(() {
                                _newProducts.removeAt(index).dispose();
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
                      label: const Text('Save'),
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

class _SponsorshipFormSection extends StatelessWidget {
  const _SponsorshipFormSection({
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

class _ProductsHeader extends StatelessWidget {
  const _ProductsHeader({
    required this.count,
    required this.onAdd,
  });

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F2),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: Color(0xFF1F7A64)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count products',
              style: const TextStyle(
                color: Color(0xFF17201D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}

class _ProductDraftFields extends StatefulWidget {
  const _ProductDraftFields({
    required this.index,
    required this.product,
    required this.onRemove,
  });

  final int index;
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
    final imageBytes = widget.product.imageBytes;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8ECEA)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF14211D),
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
            child: Text(
              widget.index.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: widget.product.name,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: widget.product.description,
                  decoration: const InputDecoration(
                    labelText: 'Product description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  minLines: 2,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 92,
                    child: imageBytes == null
                        ? const ColoredBox(
                            color: Color(0xFFF0F4F2),
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF66736F),
                            ),
                          )
                        : Image.memory(imageBytes, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(
                    widget.product.imageFileName ?? 'Select image',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            tooltip: 'Remove product',
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.close),
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
    required this.archiveTooltip,
    required this.archiveIcon,
    required this.onArchive,
    required this.onDelete,
  });

  final SponsorshipProduct product;
  final VoidCallback? onEdit;
  final String archiveTooltip;
  final IconData archiveIcon;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return SizedBox(
      width: 286,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: const Color(0xFFE8ECEA)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: imageUrl == null || imageUrl.isEmpty
                    ? null
                    : () => _showProductImagePreview(context, product),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: SizedBox(
                    width: double.infinity,
                    height: 140,
                    child: imageUrl == null || imageUrl.isEmpty
                        ? const ColoredBox(
                            color: Color(0xFFF0F4F2),
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF66736F),
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(imageUrl, fit: BoxFit.cover),
                              Align(
                                alignment: Alignment.topRight,
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xCC14211D),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(6)),
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  _StatusChip(label: product.status),
                ],
              ),
              if ((product.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  product.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF66736F),
                    fontSize: 13,
                  ),
                ),
              ],
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
                    tooltip: archiveTooltip,
                    icon: Icon(archiveIcon),
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

  Future<void> _showProductImagePreview(
    BuildContext context,
    SponsorshipProduct product,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => _ProductImagePreviewDialog(product: product),
    );
  }
}

class _ProductImagePreviewDialog extends StatelessWidget {
  const _ProductImagePreviewDialog({required this.product});

  final SponsorshipProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: imageUrl == null || imageUrl.isEmpty
                      ? const SizedBox(
                          height: 320,
                          child: ColoredBox(
                            color: Color(0xFFF0F4F2),
                            child: Center(child: Icon(Icons.image_outlined)),
                          ),
                        )
                      : InteractiveViewer(
                          minScale: 0.7,
                          maxScale: 4,
                          child: Image.network(imageUrl, fit: BoxFit.contain),
                        ),
                ),
              ),
            ),
          ],
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
    final replacementImage = _imageBytes;
    final currentImageUrl = widget.product.imageUrl;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Product',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.sponsorship.sponsorName,
                  style: const TextStyle(color: Color(0xFF66736F)),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 260,
                        child: _ProductEditImagePanel(
                          replacementImage: replacementImage,
                          currentImageUrl: currentImageUrl,
                          fileName: _imageFileName,
                          onPickImage: _pickImage,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SponsorshipFormSection(
                          icon: Icons.inventory_2_outlined,
                          title: 'Product Details',
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Product name',
                                  border: OutlineInputBorder(),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
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
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                ),
                                minLines: 5,
                                maxLines: 8,
                              ),
                            ],
                          ),
                        ),
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
                      label: const Text('Save'),
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

class _ProductEditImagePanel extends StatelessWidget {
  const _ProductEditImagePanel({
    required this.replacementImage,
    required this.currentImageUrl,
    required this.fileName,
    required this.onPickImage,
  });

  final Uint8List? replacementImage;
  final String? currentImageUrl;
  final String? fileName;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F8),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        border: Border.all(color: const Color(0xFFE8ECEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.image_outlined, size: 19, color: Color(0xFF1F7A64)),
              SizedBox(width: 8),
              Text(
                'Product Image',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: SizedBox(
              height: 210,
              child: replacementImage != null
                  ? Image.memory(replacementImage!, fit: BoxFit.cover)
                  : currentImageUrl == null || currentImageUrl!.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFF0F4F2),
                          child: Icon(
                            Icons.image_outlined,
                            color: Color(0xFF66736F),
                          ),
                        )
                      : Image.network(currentImageUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(
              fileName ?? 'Replace image',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
      'Archived' => (
          background: const Color(0xFFFFF3D6),
          foreground: const Color(0xFF8A5A00),
        ),
      'Deleted' => (
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

String _formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
