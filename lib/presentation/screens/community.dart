import 'package:flutter/material.dart';

import '../../controllers/admin_community_controller.dart';
import '../../controllers/users_controller.dart';
import '../../models/admin_community_post.dart';
import '../../models/admin_user.dart';

class CommunityPage extends StatefulWidget {
  CommunityPage({
    super.key,
    AdminCommunityController? controller,
    UsersController? usersController,
  }) : controller = controller ?? AdminCommunityController(),
       usersController = usersController ?? UsersController();

  final AdminCommunityController controller;
  final UsersController usersController;

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  _CommunityView _selectedView = _CommunityView.posts;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    widget.usersController.addListener(_handleControllerChanged);
    widget.controller.loadCommunity();
    widget.usersController.loadUsers();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    widget.usersController.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final usersController = widget.usersController;

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
                        'Community',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17201D),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'View posts, engagement, images, and content status from the patient community.',
                        style: TextStyle(
                          color: Color(0xFF66736F),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: controller.isLoading || controller.isLoadingReports
                      ? null
                      : controller.loadCommunity,
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
              children: [
                _MetricCard(
                  icon: Icons.article_outlined,
                  label: 'Total posts',
                  value: controller.posts.length.toString(),
                  isSelected: _selectedView == _CommunityView.posts,
                  onTap: () =>
                      setState(() => _selectedView = _CommunityView.posts),
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  icon: Icons.people_outline,
                  label: 'Users',
                  value: usersController.users.length.toString(),
                  isSelected: _selectedView == _CommunityView.users,
                  onTap: () =>
                      setState(() => _selectedView = _CommunityView.users),
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  icon: Icons.flag_outlined,
                  label: 'Pending reports',
                  value: controller.pendingReportCount.toString(),
                  isSelected: _selectedView == _CommunityView.reports,
                  onTap: () =>
                      setState(() => _selectedView = _CommunityView.reports),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: _selectedView == _CommunityView.posts
                    ? _CommunityPostsBody(controller: controller)
                    : _selectedView == _CommunityView.users
                    ? _CommunityUsersBody(
                        usersController: usersController,
                        communityController: controller,
                      )
                    : _CommunityReportsBody(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _CommunityView { posts, users, reports }

class _CommunityPostsBody extends StatelessWidget {
  const _CommunityPostsBody({required this.controller});

  final AdminCommunityController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.posts.isEmpty) {
      return const Center(child: Text('No community posts found.'));
    }

    return _PostsTable(posts: controller.posts, controller: controller);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF55C7A1)
                    : const Color(0xFFE7ECE9),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFBFE8D8),
                  child: Icon(icon, color: const Color(0xFF14211D), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF17201D),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF66736F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (onTap != null) ...[
                  const Spacer(),
                  const Icon(
                    Icons.table_rows_outlined,
                    color: Color(0xFF66736F),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _PostStatusFilter { all, active, archived, deleted }

enum _PostSortOption {
  newest,
  oldest,
  mostLikes,
  mostComments,
  mostImages,
  author,
}

class _PostsTable extends StatefulWidget {
  const _PostsTable({required this.posts, required this.controller});

  final List<AdminCommunityPost> posts;
  final AdminCommunityController controller;

  @override
  State<_PostsTable> createState() => _PostsTableState();
}

class _PostsTableState extends State<_PostsTable> {
  final TextEditingController _searchController = TextEditingController();
  _PostStatusFilter _statusFilter = _PostStatusFilter.all;
  _PostSortOption _sortOption = _PostSortOption.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminCommunityPost> get _visiblePosts {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.posts.where((post) {
      final matchesStatus = switch (_statusFilter) {
        _PostStatusFilter.all => true,
        _PostStatusFilter.active => post.status == 'Active',
        _PostStatusFilter.archived => post.status == 'Archived',
        _PostStatusFilter.deleted => post.status == 'Deleted',
      };
      if (!matchesStatus) return false;
      if (query.isEmpty) return true;

      return post.id.toLowerCase().contains(query) ||
          post.patientId.toLowerCase().contains(query) ||
          post.displayAuthor.toLowerCase().contains(query) ||
          post.content.toLowerCase().contains(query) ||
          post.status.toLowerCase().contains(query) ||
          _formatDate(post.createdAt).toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      return switch (_sortOption) {
        _PostSortOption.newest => b.createdAt.compareTo(a.createdAt),
        _PostSortOption.oldest => a.createdAt.compareTo(b.createdAt),
        _PostSortOption.mostLikes => b.likeCount.compareTo(a.likeCount),
        _PostSortOption.mostComments => b.commentCount.compareTo(
          a.commentCount,
        ),
        _PostSortOption.mostImages => b.imageUrls.length.compareTo(
          a.imageUrls.length,
        ),
        _PostSortOption.author => a.displayAuthor.toLowerCase().compareTo(
          b.displayAuthor.toLowerCase(),
        ),
      };
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final visiblePosts = _visiblePosts;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Community Posts',
                  style: TextStyle(
                    color: Color(0xFF17201D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${visiblePosts.length} shown',
                style: const TextStyle(
                  color: Color(0xFF66736F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ResponsiveFilters(
            children: [
              _SearchFilterBox(
                width: 420,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: _searchDecoration(
                    'Search author, content, status, date, or ID',
                  ),
                ),
              ),
              _SmallDropdown<_PostStatusFilter>(
                value: _statusFilter,
                items: const {
                  _PostStatusFilter.all: 'All status',
                  _PostStatusFilter.active: 'Active',
                  _PostStatusFilter.archived: 'Archived',
                  _PostStatusFilter.deleted: 'Deleted',
                },
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
              _SmallDropdown<_PostSortOption>(
                value: _sortOption,
                items: const {
                  _PostSortOption.newest: 'Newest',
                  _PostSortOption.oldest: 'Oldest',
                  _PostSortOption.mostLikes: 'Most likes',
                  _PostSortOption.mostComments: 'Most comments',
                  _PostSortOption.mostImages: 'Most images',
                  _PostSortOption.author: 'Author A-Z',
                },
                onChanged: (value) => setState(() => _sortOption = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visiblePosts.isEmpty
                ? const Center(
                    child: Text('No posts match the current search.'),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF3F7F5),
                        ),
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        headingRowHeight: 42,
                        dividerThickness: 1,
                        dataTextStyle: const TextStyle(
                          color: Color(0xFF46534F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        dataRowMinHeight: 54,
                        dataRowMaxHeight: 54,
                        columns: const [
                          DataColumn(label: _HeaderText('Author')),
                          DataColumn(label: _HeaderText('Content')),
                          DataColumn(label: _HeaderText('Status')),
                          DataColumn(label: _HeaderText('Likes')),
                          DataColumn(label: _HeaderText('Comments')),
                          DataColumn(label: _HeaderText('Images')),
                          DataColumn(label: _HeaderText('Created')),
                        ],
                        rows: [
                          for (final post in visiblePosts)
                            DataRow(
                              color: _hoverRowColor(),
                              onSelectChanged: (_) => _showPostDetails(
                                context,
                                widget.controller,
                                post,
                              ),
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 130,
                                    child: Text(
                                      post.displayAuthor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 230,
                                    child: Text(
                                      post.content,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(_StatusBadge(status: post.status)),
                                DataCell(
                                  Text(
                                    post.likeCount.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    post.commentCount.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    post.imageUrls.length.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(post.createdAt),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SmallDropdown<T> extends StatelessWidget {
  const _SmallDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            color: Color(0xFF17201D),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          items: [
            for (final entry in items.entries)
              DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) {
            onChanged(value as T);
          },
        ),
      ),
    );
  }
}

class _SearchFilterBox extends StatelessWidget {
  const _SearchFilterBox({
    required this.child,
    this.width = 360,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _ResponsiveFilters extends StatelessWidget {
  const _ResponsiveFilters({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

InputDecoration _searchDecoration(String hintText) {
  return InputDecoration(
    isDense: true,
    prefixIcon: const Icon(Icons.search, size: 18),
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFF8FBF9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
    ),
  );
}

WidgetStateProperty<Color?> _hoverRowColor() {
  return WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.hovered)) {
      return const Color(0xFFEFF7F3);
    }
    if (states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.selected)) {
      return const Color(0xFFE5F6EF);
    }
    return null;
  });
}

class _CommunityUsersBody extends StatefulWidget {
  const _CommunityUsersBody({
    required this.usersController,
    required this.communityController,
  });

  final UsersController usersController;
  final AdminCommunityController communityController;

  @override
  State<_CommunityUsersBody> createState() => _CommunityUsersBodyState();
}

class _CommunityUsersBodyState extends State<_CommunityUsersBody> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.usersController;

    if (_searchController.text != controller.searchQuery) {
      _searchController.value = TextEditingValue(
        text: controller.searchQuery,
        selection: TextSelection.collapsed(
          offset: controller.searchQuery.length,
        ),
      );
    }

    if (controller.isLoading && controller.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return _PanelMessage(
        icon: Icons.error_outline,
        title: controller.errorMessage!,
        action: FilledButton.icon(
          onPressed: controller.loadUsers,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    if (controller.users.isEmpty) {
      return const _PanelMessage(
        icon: Icons.people_alt_outlined,
        title: 'No users found.',
      );
    }

    final users = controller.filteredUsers;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Community Users',
                  style: TextStyle(
                    color: Color(0xFF17201D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${users.length} shown',
                style: const TextStyle(
                  color: Color(0xFF66736F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search name, ID, status, role, gender, or date',
                    filled: true,
                    fillColor: const Color(0xFFF8FBF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
                    ),
                    suffixIcon: controller.searchQuery.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.updateSearchQuery('');
                            },
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SmallDropdown<String?>(
                value: controller.roleFilter,
                items: {
                  null: 'All roles',
                  for (final role in controller.roleOptions) role: role,
                },
                onChanged: controller.updateRoleFilter,
              ),
              const SizedBox(width: 10),
              _SmallDropdown<String?>(
                value: controller.genderFilter,
                items: {
                  null: 'All gender',
                  for (final gender in controller.genderOptions) gender: gender,
                },
                onChanged: controller.updateGenderFilter,
              ),
              const SizedBox(width: 10),
              _SmallDropdown<JoinedDateSort>(
                value: controller.joinedDateSort,
                items: const {
                  JoinedDateSort.newestFirst: 'Newest',
                  JoinedDateSort.oldestFirst: 'Oldest',
                },
                onChanged: controller.updateJoinedDateSort,
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: controller.hasActiveFilters
                    ? controller.clearFilters
                    : null,
                tooltip: 'Clear filters',
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (users.isEmpty)
            const Expanded(
              child: Center(child: Text('No users match the current filters.')),
            )
          else
            Expanded(
              child: Column(
                children: [
                  const _CommunityUsersTableHeader(),
                  Expanded(
                    child: ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _CommunityUserRow(
                          user: user,
                          posts: widget.communityController.posts,
                          communityController: widget.communityController,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CommunityReportsBody extends StatefulWidget {
  const _CommunityReportsBody({required this.controller});

  final AdminCommunityController controller;

  @override
  State<_CommunityReportsBody> createState() => _CommunityReportsBodyState();
}

enum _ReportTargetFilter { all, posts, comments }

enum _ReportStatusFilter { all, pending, reviewed, dismissed }

enum _ReportDateSort { newest, oldest }

class _CommunityReportsBodyState extends State<_CommunityReportsBody> {
  final TextEditingController _searchController = TextEditingController();
  _ReportTargetFilter _targetFilter = _ReportTargetFilter.all;
  _ReportStatusFilter _statusFilter = _ReportStatusFilter.all;
  String? _reasonFilter;
  _ReportDateSort _dateSort = _ReportDateSort.newest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminCommunityReport> get _visibleReports {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.controller.reports.where((report) {
      final matchesTarget = switch (_targetFilter) {
        _ReportTargetFilter.all => true,
        _ReportTargetFilter.posts => report.isPostReport,
        _ReportTargetFilter.comments => !report.isPostReport,
      };
      final matchesStatus = switch (_statusFilter) {
        _ReportStatusFilter.all => true,
        _ReportStatusFilter.pending => report.status == 'pending',
        _ReportStatusFilter.reviewed => report.status == 'reviewed',
        _ReportStatusFilter.dismissed => report.status == 'dismissed',
      };
      final matchesReason =
          _reasonFilter == null || report.reason == _reasonFilter;
      if (!matchesTarget || !matchesStatus || !matchesReason) return false;
      if (query.isEmpty) return true;

      return report.id.toLowerCase().contains(query) ||
          report.displayReporter.toLowerCase().contains(query) ||
          report.displayReportedAuthor.toLowerCase().contains(query) ||
          report.reason.toLowerCase().contains(query) ||
          report.status.toLowerCase().contains(query) ||
          report.targetType.toLowerCase().contains(query) ||
          report.displayContent.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final comparison = b.createdAt.compareTo(a.createdAt);
      return _dateSort == _ReportDateSort.newest ? comparison : -comparison;
    });
    return filtered;
  }

  List<String> get _reasonOptions {
    final reasons = {
      for (final report in widget.controller.reports)
        if (report.reason.trim().isNotEmpty) report.reason,
    }.toList();
    reasons.sort();
    return reasons;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final visibleReports = _visibleReports;
    final pendingCount = controller.reports
        .where((report) => report.status == 'pending')
        .length;
    final reviewedCount = controller.reports
        .where((report) => report.status == 'reviewed')
        .length;
    final dismissedCount = controller.reports
        .where((report) => report.status == 'dismissed')
        .length;

    if (controller.isLoadingReports && controller.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.reportsErrorMessage != null) {
      return _PanelMessage(
        icon: Icons.error_outline,
        title: controller.reportsErrorMessage!,
        action: FilledButton.icon(
          onPressed: controller.loadReports,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    if (controller.reports.isEmpty) {
      return const _PanelMessage(
        icon: Icons.flag_outlined,
        title: 'No user reports found.',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'User Reports',
                  style: TextStyle(
                    color: Color(0xFF17201D),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${visibleReports.length} shown',
                style: const TextStyle(
                  color: Color(0xFF66736F),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReportCountPill(label: 'Pending', value: pendingCount),
              _ReportCountPill(label: 'Reviewed', value: reviewedCount),
              _ReportCountPill(label: 'Dismissed', value: dismissedCount),
              _ReportCountPill(label: 'Total', value: controller.reports.length),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Search reporter, reason, content, status, or ID',
                    filled: true,
                    fillColor: const Color(0xFFF8FBF9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE7ECE9)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _SmallDropdown<_ReportTargetFilter>(
                value: _targetFilter,
                items: const {
                  _ReportTargetFilter.all: 'All targets',
                  _ReportTargetFilter.posts: 'Posts',
                  _ReportTargetFilter.comments: 'Comments',
                },
                onChanged: (value) => setState(() => _targetFilter = value),
              ),
              const SizedBox(width: 10),
              _SmallDropdown<_ReportStatusFilter>(
                value: _statusFilter,
                items: const {
                  _ReportStatusFilter.all: 'All status',
                  _ReportStatusFilter.pending: 'Pending',
                  _ReportStatusFilter.reviewed: 'Reviewed',
                  _ReportStatusFilter.dismissed: 'Dismissed',
                },
                onChanged: (value) => setState(() => _statusFilter = value),
              ),
              const SizedBox(width: 10),
              _SmallDropdown<String?>(
                value: _reasonFilter,
                items: {
                  null: 'All reasons',
                  for (final reason in _reasonOptions) reason: reason,
                },
                onChanged: (value) => setState(() => _reasonFilter = value),
              ),
              const SizedBox(width: 10),
              _SmallDropdown<_ReportDateSort>(
                value: _dateSort,
                items: const {
                  _ReportDateSort.newest: 'Newest',
                  _ReportDateSort.oldest: 'Oldest',
                },
                onChanged: (value) => setState(() => _dateSort = value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visibleReports.isEmpty
                ? const Center(
                    child: Text('No reports match the current filters.'),
                  )
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        showCheckboxColumn: false,
                        headingRowColor: WidgetStateProperty.all(
                          const Color(0xFFF3F7F5),
                        ),
                        columnSpacing: 16,
                        horizontalMargin: 12,
                        headingRowHeight: 42,
                        dividerThickness: 1,
                        dataTextStyle: const TextStyle(
                          color: Color(0xFF46534F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        dataRowMinHeight: 54,
                        dataRowMaxHeight: 58,
                        columns: const [
                          DataColumn(label: _HeaderText('Reporter')),
                          DataColumn(label: _HeaderText('Target')),
                          DataColumn(label: _HeaderText('Reported User')),
                          DataColumn(label: _HeaderText('Reason')),
                          DataColumn(label: _HeaderText('Status')),
                          DataColumn(label: _HeaderText('Content')),
                          DataColumn(label: _HeaderText('Created')),
                        ],
                        rows: [
                          for (final report in visibleReports)
                            DataRow(
                              color: _hoverRowColor(),
                              onSelectChanged: (_) => _showReportDetails(
                                context,
                                report,
                                widget.controller,
                              ),
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      report.displayReporter,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _TargetChip(targetType: report.targetType),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      report.displayReportedAuthor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 190,
                                    child: Text(
                                      report.reason,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  _ReportStatusChip(status: report.status),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 260,
                                    child: Text(
                                      report.displayContent,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _formatDate(report.createdAt),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommunityUsersTableHeader extends StatelessWidget {
  const _CommunityUsersTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F7F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('User')),
          Expanded(flex: 2, child: _HeaderText('Status')),
          Expanded(flex: 2, child: _HeaderText('Role')),
          Expanded(flex: 2, child: _HeaderText('Gender')),
          Expanded(flex: 3, child: _HeaderText('Phone')),
          Expanded(flex: 2, child: _HeaderText('Joined')),
          Expanded(flex: 2, child: _HeaderText('Public Posts')),
          SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _CommunityUserRow extends StatelessWidget {
  const _CommunityUserRow({
    required this.user,
    required this.posts,
    required this.communityController,
  });

  final AdminUser user;
  final List<AdminCommunityPost> posts;
  final AdminCommunityController communityController;

  List<AdminCommunityPost> get _publicPosts {
    return posts
        .where(
          (post) =>
              post.patientId == user.id && !post.isDeleted && !post.isArchived,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final publicPosts = _publicPosts;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCommunityUserProfile(
          context,
          user,
          publicPosts,
          communityController,
        ),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      _UserAvatar(user: user),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF17201D),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              user.shortId,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF66736F),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _UserStatusChip(isActive: user.isActive),
                ),
                Expanded(flex: 2, child: _UserRoleChip(role: user.role)),
                Expanded(flex: 2, child: _CellText(user.gender ?? '-')),
                Expanded(flex: 3, child: _CellText(user.phoneNo ?? '-')),
                Expanded(
                  flex: 2,
                  child: _CellText(_formatDate(user.createdAt)),
                ),
                Expanded(
                  flex: 2,
                  child: _CellText(publicPosts.length.toString()),
                ),
                const SizedBox(
                  width: 28,
                  child: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF9AA7A2),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  const _HeaderText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF66736F),
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, this.radius = 16});

  final AdminUser user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFBFE8D8),
      backgroundImage: avatarUrl == null || avatarUrl.isEmpty
          ? null
          : NetworkImage(avatarUrl),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(Icons.person_outline, color: Color(0xFF14211D), size: 18)
          : null,
    );
  }
}

class _UserStatusChip extends StatelessWidget {
  const _UserStatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F3EF) : const Color(0xFFF4EDEA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isActive ? 'Active' : 'Deactivated',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isActive ? const Color(0xFF1F7A64) : const Color(0xFF8A4B38),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UserRoleChip extends StatelessWidget {
  const _UserRoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFFE8F3EF) : const Color(0xFFF0F4F2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          role,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isAdmin ? const Color(0xFF1F7A64) : const Color(0xFF66736F),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CellText extends StatelessWidget {
  const _CellText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF46534F),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  const _PanelMessage({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: const Color(0xFF66736F)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({required this.targetType});

  final String targetType;

  @override
  Widget build(BuildContext context) {
    final isPost = targetType == 'Post';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isPost ? const Color(0xFFE5F6EF) : const Color(0xFFEFF3FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPost ? Icons.article_outlined : Icons.chat_bubble_outline,
            size: 14,
            color: isPost ? const Color(0xFF1F7A55) : const Color(0xFF4256A6),
          ),
          const SizedBox(width: 5),
          Text(
            targetType,
            style: TextStyle(
              color: isPost ? const Color(0xFF1F7A55) : const Color(0xFF4256A6),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportStatusChip extends StatelessWidget {
  const _ReportStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = normalized == 'pending'
        ? const Color(0xFF8A5A00)
        : normalized == 'dismissed'
        ? const Color(0xFF66736F)
        : const Color(0xFF1F7A55);
    final background = normalized == 'pending'
        ? const Color(0xFFFFF3CD)
        : normalized == 'dismissed'
        ? const Color(0xFFF1F5F3)
        : const Color(0xFFE5F6EF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ReportCountPill extends StatelessWidget {
  const _ReportCountPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: Color(0xFF33413D),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CommentStatusBadge extends StatelessWidget {
  const _CommentStatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDeleted = label == 'Deleted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDeleted ? const Color(0xFFFFECEC) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDeleted ? const Color(0xFFB3261E) : const Color(0xFF8A5A00),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Future<void> _showReportDetails(
  BuildContext context,
  AdminCommunityReport report,
  AdminCommunityController controller,
) {
  final isResolvedReport = report.status != 'pending';
  final isReportedContentArchived =
      report.post?.isArchived == true || report.comment?.isArchived == true;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF8FBF9),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 760,
          height: 700,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Avatar(
                      name: report.displayReporter,
                      imageUrl: report.reporterAvatarUrl,
                      radius: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reported by ${report.displayReporter}',
                            style: const TextStyle(
                              color: Color(0xFF17201D),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatDate(report.createdAt),
                            style: const TextStyle(
                              color: Color(0xFF66736F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TargetChip(targetType: report.targetType),
                    const SizedBox(width: 8),
                    _ReportStatusChip(status: report.status),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7ECE9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report reason',
                        style: TextStyle(
                          color: Color(0xFF66736F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.reason,
                        style: const TextStyle(
                          color: Color(0xFF17201D),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SectionTitle(title: 'Reported Content'),
                const SizedBox(height: 10),
                if (report.post != null)
                  _ReportedPostCard(post: report.post!, controller: controller)
                else if (report.comment != null)
                  _ReportedCommentCard(comment: report.comment!)
                else
                  const _EmptyText(
                    'The reported content is no longer available.',
                  ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ProfileInfoPill(label: 'Report ID', value: report.id),
                    _ProfileInfoPill(
                      label: 'Reporter ID',
                      value: report.reporterId,
                    ),
                    _ProfileInfoPill(
                      label: 'Target ID',
                      value: report.postId ?? report.commentId ?? '-',
                    ),
                    _ProfileInfoPill(
                      label: 'Reviewed by',
                      value: report.reviewedBy ?? '-',
                    ),
                    _ProfileInfoPill(
                      label: 'Resolution',
                      value: report.resolutionAction ?? '-',
                    ),
                    _ProfileInfoPill(
                      label: 'Resolved at',
                      value: report.resolvedAt == null
                          ? '-'
                          : _formatDate(report.resolvedAt!),
                    ),
                  ],
                ),
                if (report.resolutionNote?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  const _SectionTitle(title: 'Resolution Note'),
                  const SizedBox(height: 8),
                  Text(
                    report.resolutionNote!,
                    style: const TextStyle(
                      color: Color(0xFF33413D),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: controller.isModerating
                ? null
                : () async {
                    final note = await _showReportNoteDialog(
                      context,
                      title: 'Dismiss report',
                      hintText: 'Why is this report being dismissed?',
                    );
                    if (note == null) return;
                    final success = await controller.dismissReport(
                      report.id,
                      note: note,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    if (!context.mounted) return;
                    _showModerationSnack(
                      context,
                      success ? 'Report dismissed.' : 'Unable to dismiss report.',
                    );
                  },
            icon: const Icon(Icons.close_outlined),
            label: const Text('Dismiss'),
          ),
          TextButton.icon(
            onPressed: controller.isModerating
                ? null
                : () async {
                    final note = await _showReportNoteDialog(
                      context,
                      title: 'Mark reviewed',
                      hintText: 'Optional review note...',
                    );
                    if (note == null) return;
                    final success = await controller.markReportReviewed(
                      report.id,
                      note: note,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    if (!context.mounted) return;
                    _showModerationSnack(
                      context,
                      success
                          ? 'Report marked reviewed.'
                          : 'Unable to update report.',
                    );
                  },
            icon: const Icon(Icons.done_all_outlined),
            label: const Text('Reviewed'),
          ),
          if (report.reportedUserId != null && report.targetId != null)
            TextButton.icon(
              onPressed: controller.isModerating
                  ? null
                  : () => _showWarningDialog(
                      context,
                      controller: controller,
                      userId: report.reportedUserId!,
                      targetType: report.targetType.toLowerCase(),
                      targetId: report.targetId!,
                      submitLabel: 'Warn and resolve',
                      successMessage: 'Warning sent and report reviewed.',
                      failureMessage: 'Unable to warn user.',
                      onSubmit: (warning) => controller.warnAndResolveReport(
                        report,
                        warning,
                        archiveContent: false,
                      ),
                    ).then((submitted) {
                      if (submitted == true && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    }),
              icon: const Icon(Icons.warning_amber_outlined),
              label: const Text('Warn'),
            ),
          FilledButton.icon(
            onPressed:
                controller.isModerating ||
                    report.targetId == null ||
                    isReportedContentArchived
                ? null
                : () async {
                    final success = await controller.archiveAndResolveReport(
                      report,
                    );
                    if (!dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop();
                    if (!context.mounted) return;
                    _showModerationSnack(
                      context,
                      success
                          ? 'Content archived and report reviewed.'
                          : 'Unable to archive reported content.',
                    );
                  },
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
          if (isResolvedReport && isReportedContentArchived)
            FilledButton.icon(
              onPressed: controller.isModerating
                  ? null
                  : () async {
                      final success = await controller.unarchiveReportedContent(
                        report,
                      );
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      _showModerationSnack(
                        context,
                        success
                            ? 'Reported content unarchived.'
                            : 'Unable to unarchive reported content.',
                      );
                    },
              icon: const Icon(Icons.unarchive_outlined),
              label: const Text('Unarchive'),
            ),
          if (report.reportedUserId != null &&
              report.targetId != null &&
              !isReportedContentArchived)
            FilledButton.icon(
              onPressed: controller.isModerating
                  ? null
                  : () => _showWarningDialog(
                      context,
                      controller: controller,
                      userId: report.reportedUserId!,
                      targetType: report.targetType.toLowerCase(),
                      targetId: report.targetId!,
                      submitLabel: 'Archive + warn',
                      successMessage:
                          'Content archived, warning sent, and report reviewed.',
                      failureMessage: 'Unable to archive and warn.',
                      onSubmit: (warning) => controller.warnAndResolveReport(
                        report,
                        warning,
                        archiveContent: true,
                      ),
                    ).then((submitted) {
                      if (submitted == true && dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    }),
              icon: const Icon(Icons.gpp_maybe_outlined),
              label: const Text('Archive + Warn'),
            ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<String?> _showReportNoteDialog(
  BuildContext context, {
  required String title,
  required String hintText,
}) {
  final noteController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: noteController,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(noteController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      );
    },
  ).whenComplete(noteController.dispose);
}

void _showModerationSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _ReportedPostCard extends StatelessWidget {
  const _ReportedPostCard({required this.post, required this.controller});

  final AdminCommunityPost post;
  final AdminCommunityController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showPostDetails(context, controller, post),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7ECE9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(
                    name: post.displayAuthor,
                    imageUrl: post.authorAvatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.displayAuthor,
                          style: const TextStyle(
                            color: Color(0xFF17201D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(
                            color: Color(0xFF66736F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: post.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(color: Color(0xFF17201D), height: 1.4),
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ImageGrid(imageUrls: post.imageUrls),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportedCommentCard extends StatelessWidget {
  const _ReportedCommentCard({required this.comment});

  final AdminCommunityComment comment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(
            name: comment.displayAuthor,
            imageUrl: comment.authorAvatarUrl,
            radius: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.displayAuthor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF17201D),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (comment.isDeleted) ...[
                      const SizedBox(width: 8),
                      const _CommentStatusBadge(label: 'Deleted'),
                    ],
                    if (comment.isArchived) ...[
                      const SizedBox(width: 8),
                      const _CommentStatusBadge(label: 'Archived'),
                    ],
                    Text(
                      _formatDate(comment.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF66736F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  comment.content,
                  style: const TextStyle(color: Color(0xFF17201D), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCommunityUserProfile(
  BuildContext context,
  AdminUser user,
  List<AdminCommunityPost> publicPosts,
  AdminCommunityController communityController,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF8FBF9),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 760,
          height: 700,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _UserAvatar(user: user, radius: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName,
                            style: const TextStyle(
                              color: Color(0xFF17201D),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.id,
                            style: const TextStyle(
                              color: Color(0xFF66736F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _UserStatusChip(isActive: user.isActive),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE7ECE9)),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _ProfileInfoPill(label: 'Role', value: user.role),
                      _ProfileInfoPill(
                        label: 'Gender',
                        value: user.gender ?? '-',
                      ),
                      _ProfileInfoPill(
                        label: 'Phone',
                        value: user.phoneNo ?? '-',
                      ),
                      _ProfileInfoPill(
                        label: 'Joined',
                        value: _formatDate(user.createdAt),
                      ),
                      _ProfileInfoPill(
                        label: 'Subscription',
                        value: user.isSubscribed ? 'Active' : 'Not active',
                      ),
                      _ProfileInfoPill(
                        label: 'Public posts',
                        value: publicPosts.length.toString(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const _SectionTitle(title: 'Public Posts'),
                const SizedBox(height: 10),
                if (publicPosts.isEmpty)
                  const _EmptyText('This user has no active public posts.')
                else
                  ...publicPosts.map(
                    (post) => _UserPublicPostCard(
                      post: post,
                      controller: communityController,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _ProfileInfoPill extends StatelessWidget {
  const _ProfileInfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserPublicPostCard extends StatelessWidget {
  const _UserPublicPostCard({required this.post, required this.controller});

  final AdminCommunityPost post;
  final AdminCommunityController controller;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showPostDetails(context, controller, post),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE7ECE9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF66736F),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _Stat(icon: Icons.favorite_border, value: post.likeCount),
                  _Stat(
                    icon: Icons.chat_bubble_outline,
                    value: post.commentCount,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17201D),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (post.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 86,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: post.imageUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          post.imageUrls[index],
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 86,
                            height: 86,
                            color: const Color(0xFFE7ECE9),
                            alignment: Alignment.center,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final isDeleted = status == 'Deleted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFE5F6EF)
            : isDeleted
            ? const Color(0xFFFFECEC)
            : const Color(0xFFF1F5F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive
              ? const Color(0xFF1F7A55)
              : isDeleted
              ? const Color(0xFFB3261E)
              : const Color(0xFF66736F),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF66736F)),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.imageUrl, this.radius = 18});

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.trim().isNotEmpty == true;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFBFE8D8),
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      child: hasImage
          ? null
          : Text(
              initial,
              style: const TextStyle(
                color: Color(0xFF14211D),
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

Future<bool?> _showWarningDialog(
  BuildContext context, {
  required AdminCommunityController controller,
  required String userId,
  required String targetType,
  required String targetId,
  Future<bool> Function(AdminUserWarning warning)? onSubmit,
  String submitLabel = 'Send warning',
  String successMessage = 'Warning sent.',
  String failureMessage = 'Unable to send warning.',
}) {
  const reasons = [
    'Inappropriate content',
    'Harassment or bullying',
    'Spam or misleading content',
    'Privacy concern',
    'Unsafe or harmful content',
    'Other',
  ];
  var selectedReason = reasons.first;
  final descriptionController = TextEditingController();

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Send Warning'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a reason',
                    style: TextStyle(
                      color: Color(0xFF66736F),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedReason,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    items: [
                      for (final reason in reasons)
                        DropdownMenuItem(value: reason, child: Text(reason)),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedReason = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Description (optional)',
                    style: TextStyle(
                      color: Color(0xFF66736F),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Add extra context for the user...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: controller.isModerating
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: controller.isModerating
                    ? null
                    : () async {
                        final warning = AdminUserWarning(
                          userId: userId,
                          targetType: targetType,
                          targetId: targetId,
                          reason: selectedReason,
                          description: descriptionController.text,
                        );
                        final success = onSubmit == null
                            ? await controller.sendWarning(warning)
                            : await onSubmit(warning);
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(success);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? successMessage : failureMessage,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.warning_amber_outlined),
                label: Text(submitLabel),
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(descriptionController.dispose);
}

Future<void> _confirmTogglePostArchive(
  BuildContext context,
  AdminCommunityController controller,
  AdminCommunityPost post,
) {
  final shouldUnarchive = post.isArchived;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(shouldUnarchive ? 'Unarchive post?' : 'Archive post?'),
        content: Text(
          shouldUnarchive
              ? 'This post will become active community content again.'
              : 'Archived posts will no longer be treated as active community content.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final success = shouldUnarchive
                  ? await controller.unarchivePost(post.id)
                  : await controller.archivePost(post.id);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              if (success) Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? shouldUnarchive
                              ? 'Post unarchived.'
                              : 'Post archived.'
                        : shouldUnarchive
                        ? 'Unable to unarchive post.'
                        : 'Unable to archive post.',
                  ),
                ),
              );
            },
            icon: Icon(
              shouldUnarchive
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(shouldUnarchive ? 'Unarchive' : 'Archive'),
          ),
        ],
      );
    },
  );
}

Future<void> _confirmToggleCommentArchive(
  BuildContext context,
  AdminCommunityController controller,
  AdminCommunityComment comment,
) {
  final shouldUnarchive = comment.isArchived;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          shouldUnarchive ? 'Unarchive comment?' : 'Archive comment?',
        ),
        content: Text(
          shouldUnarchive
              ? 'This comment will become visible in active community discussion again.'
              : 'Archived comments will be hidden from active community discussion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final success = shouldUnarchive
                  ? await controller.unarchiveComment(comment.id)
                  : await controller.archiveComment(comment.id);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              if (success) Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? shouldUnarchive
                              ? 'Comment unarchived.'
                              : 'Comment archived.'
                        : shouldUnarchive
                        ? 'Unable to unarchive comment.'
                        : 'Unable to archive comment.',
                  ),
                ),
              );
            },
            icon: Icon(
              shouldUnarchive
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            label: Text(shouldUnarchive ? 'Unarchive' : 'Archive'),
          ),
        ],
      );
    },
  );
}

Future<void> _showPostDetails(
  BuildContext context,
  AdminCommunityController controller,
  AdminCommunityPost post,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF8FBF9),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 720,
          height: 680,
          child: FutureBuilder<AdminCommunityPostDetails>(
            future: controller.loadPostDetails(post),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(
                  child: Text('Unable to load post details.'),
                );
              }

              return _PostDetailsContent(
                details: snapshot.data!,
                controller: controller,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

class _PostDetailsContent extends StatelessWidget {
  const _PostDetailsContent({required this.details, required this.controller});

  final AdminCommunityPostDetails details;
  final AdminCommunityController controller;

  @override
  Widget build(BuildContext context) {
    final post = details.post;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                name: post.displayAuthor,
                imageUrl: post.authorAvatarUrl,
                radius: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.displayAuthor,
                      style: const TextStyle(
                        color: Color(0xFF17201D),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(
                        color: Color(0xFF66736F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: post.status),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE7ECE9)),
            ),
            child: Text(
              post.content,
              style: const TextStyle(
                color: Color(0xFF17201D),
                fontSize: 15,
                height: 1.45,
              ),
            ),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ImageGrid(imageUrls: post.imageUrls),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: controller.isModerating
                    ? null
                    : () => _showWarningDialog(
                        context,
                        controller: controller,
                        userId: post.patientId,
                        targetType: 'post',
                        targetId: post.id,
                      ),
                icon: const Icon(Icons.warning_amber_outlined, size: 18),
                label: const Text('Send warning'),
              ),
              const SizedBox(width: 10),
              if (!post.isArchived) ...[
                FilledButton.icon(
                  onPressed: controller.isModerating
                      ? null
                      : () => _showWarningDialog(
                          context,
                          controller: controller,
                          userId: post.patientId,
                          targetType: 'post',
                          targetId: post.id,
                          submitLabel: 'Archive + warn',
                          successMessage: 'Post archived and warning sent.',
                          failureMessage: 'Unable to archive and warn.',
                          onSubmit: controller.archivePostWithWarning,
                        ),
                  icon: const Icon(Icons.gpp_maybe_outlined, size: 18),
                  label: const Text('Archive + Warn'),
                ),
                const SizedBox(width: 10),
              ],
              OutlinedButton.icon(
                onPressed: controller.isModerating
                    ? null
                    : () =>
                          _confirmTogglePostArchive(context, controller, post),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8A5A00),
                ),
                icon: Icon(
                  post.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  size: 18,
                ),
                label: Text(
                  post.isArchived ? 'Unarchive post' : 'Archive post',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _EngagementPill(
                icon: Icons.favorite,
                label: '${details.likes.length} likes',
              ),
              const SizedBox(width: 10),
              _EngagementPill(
                icon: Icons.chat_bubble,
                label: '${details.comments.length} comments',
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'Liked by'),
          const SizedBox(height: 10),
          if (details.likes.isEmpty)
            const _EmptyText('No likes yet.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final like in details.likes)
                  _PersonChip(
                    name: like.displayAuthor,
                    imageUrl: like.authorAvatarUrl,
                  ),
              ],
            ),
          const SizedBox(height: 22),
          _SectionTitle(title: 'Comments'),
          const SizedBox(height: 10),
          if (details.comments.isEmpty)
            const _EmptyText('No comments yet.')
          else
            _CommentThreadList(
              comments: details.comments,
              controller: controller,
            ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: imageUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final url = imageUrls[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE7ECE9),
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}

class _EngagementPill extends StatelessWidget {
  const _EngagementPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1F7A55)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F7A55),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF17201D),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name, required this.imageUrl});

  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE7ECE9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(name: name, imageUrl: imageUrl, radius: 14),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              color: Color(0xFF17201D),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentThreadList extends StatelessWidget {
  const _CommentThreadList({required this.comments, required this.controller});

  final List<AdminCommunityComment> comments;
  final AdminCommunityController controller;

  @override
  Widget build(BuildContext context) {
    final commentIds = comments.map((comment) => comment.id).toSet();
    final commentsByParentId = <String?, List<AdminCommunityComment>>{};

    for (final comment in comments) {
      final parentId = commentIds.contains(comment.parentId)
          ? comment.parentId
          : null;
      commentsByParentId.putIfAbsent(parentId, () => []).add(comment);
    }

    return Column(
      children: [
        for (final comment in commentsByParentId[null] ?? const [])
          _CommentTile(
            comment: comment,
            repliesByParentId: commentsByParentId,
            controller: controller,
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.repliesByParentId,
    required this.controller,
    this.depth = 0,
  });

  final AdminCommunityComment comment;
  final Map<String?, List<AdminCommunityComment>> repliesByParentId;
  final AdminCommunityController controller;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final replies = repliesByParentId[comment.id] ?? const [];
    final clampedDepth = depth > 3 ? 3 : depth;

    return Padding(
      padding: EdgeInsets.only(left: clampedDepth * 18.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (depth > 0) ...[
              Container(
                width: 2,
                margin: const EdgeInsets.only(right: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E4DE),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
            Expanded(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.only(
                      left: depth == 0 ? 0 : 2,
                      right: 0,
                      top: 2,
                      bottom: 8,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE7ECE9)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(
                          name: comment.displayAuthor,
                          imageUrl: comment.authorAvatarUrl,
                          radius: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      comment.displayAuthor,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF17201D),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (comment.isDeleted) ...[
                                    const SizedBox(width: 8),
                                    const _CommentStatusBadge(label: 'Deleted'),
                                  ],
                                  if (comment.isArchived) ...[
                                    const SizedBox(width: 8),
                                    const _CommentStatusBadge(
                                      label: 'Archived',
                                    ),
                                  ],
                                  if (depth > 0) ...[
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Reply',
                                      style: TextStyle(
                                        color: Color(0xFF1F7A55),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(comment.createdAt),
                                    style: const TextStyle(
                                      color: Color(0xFF66736F),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  color: Color(0xFF46534F),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  TextButton.icon(
                                    onPressed: controller.isModerating
                                        ? null
                                        : () => _showWarningDialog(
                                            context,
                                            controller: controller,
                                            userId: comment.patientId,
                                            targetType: 'comment',
                                            targetId: comment.id,
                                          ),
                                    icon: const Icon(
                                      Icons.warning_amber_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Warn'),
                                  ),
                                  if (!comment.isArchived)
                                    TextButton.icon(
                                      onPressed: controller.isModerating
                                          ? null
                                          : () => _showWarningDialog(
                                              context,
                                              controller: controller,
                                              userId: comment.patientId,
                                              targetType: 'comment',
                                              targetId: comment.id,
                                              submitLabel: 'Archive + warn',
                                              successMessage:
                                                  'Comment archived and warning sent.',
                                              failureMessage:
                                                  'Unable to archive and warn.',
                                              onSubmit: controller
                                                  .archiveCommentWithWarning,
                                            ),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF8A5A00,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.gpp_maybe_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Archive + Warn'),
                                    ),
                                  TextButton.icon(
                                    onPressed: controller.isModerating
                                        ? null
                                        : () => _confirmToggleCommentArchive(
                                            context,
                                            controller,
                                            comment,
                                          ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF8A5A00),
                                    ),
                                    icon: Icon(
                                      comment.isArchived
                                          ? Icons.unarchive_outlined
                                          : Icons.archive_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      comment.isArchived
                                          ? 'Unarchive'
                                          : 'Archive',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (final reply in replies)
                    _CommentTile(
                      comment: reply,
                      repliesByParentId: repliesByParentId,
                      controller: controller,
                      depth: depth + 1,
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

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF66736F),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month/${value.year} $hour:$minute';
}
