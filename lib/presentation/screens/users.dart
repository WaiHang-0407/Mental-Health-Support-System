import 'package:flutter/material.dart';

import '../../controllers/users_controller.dart';
import '../../models/admin_user.dart';

class UsersPage extends StatefulWidget {
  UsersPage({super.key, UsersController? usersController})
      : usersController = usersController ?? _DefaultUsersController();

  final UsersController usersController;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.usersController.addListener(_handleControllerChanged);
    widget.usersController.loadUsers();
  }

  @override
  void dispose() {
    widget.usersController.removeListener(_handleControllerChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.usersController;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UsersHeader(
              totalUsers: controller.users.length,
              visibleUsers: controller.filteredUsers.length,
              isLoading: controller.isLoading,
              onRefresh: controller.loadUsers,
            ),
            const SizedBox(height: 18),
            _UsersFilters(
              controller: controller,
              searchController: _searchController,
            ),
            const SizedBox(height: 22),
            Expanded(
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: _UsersBody(controller: controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultUsersController extends UsersController {
  _DefaultUsersController();
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader({
    required this.totalUsers,
    required this.visibleUsers,
    required this.isLoading,
    required this.onRefresh,
  });

  final int totalUsers;
  final int visibleUsers;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Users',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17201D),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$visibleUsers of $totalUsers accounts shown',
                style: const TextStyle(color: Color(0xFF66736F), fontSize: 15),
              ),
            ],
          ),
        ),
        IconButton.filled(
          onPressed: isLoading ? null : onRefresh,
          tooltip: 'Refresh users',
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _UsersFilters extends StatelessWidget {
  const _UsersFilters({
    required this.controller,
    required this.searchController,
  });

  final UsersController controller;
  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    if (searchController.text != controller.searchQuery) {
      searchController.value = TextEditingValue(
        text: controller.searchQuery,
        selection: TextSelection.collapsed(offset: controller.searchQuery.length),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: searchController,
            onChanged: controller.updateSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search name, ID, status, role, gender, or joined date',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        controller.updateSearchQuery('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _FilterDropdown<String>(
          width: 150,
          value: controller.roleFilter,
          hint: 'Role',
          items: controller.roleOptions,
          labelFor: (value) => value,
          onChanged: controller.updateRoleFilter,
        ),
        const SizedBox(width: 12),
        _FilterDropdown<String>(
          width: 150,
          value: controller.genderFilter,
          hint: 'Gender',
          items: controller.genderOptions,
          labelFor: (value) => value,
          onChanged: controller.updateGenderFilter,
        ),
        const SizedBox(width: 12),
        _FilterDropdown<int>(
          width: 150,
          value: controller.joinedYearFilter,
          hint: 'Joined',
          items: controller.joinedYearOptions,
          labelFor: (value) => value.toString(),
          onChanged: controller.updateJoinedYearFilter,
        ),
        const SizedBox(width: 12),
        _SortDropdown(
          value: controller.joinedDateSort,
          onChanged: controller.updateJoinedDateSort,
        ),
        const SizedBox(width: 12),
        IconButton.filledTonal(
          onPressed: controller.hasActiveFilters ? controller.clearFilters : null,
          tooltip: 'Clear filters',
          icon: const Icon(Icons.filter_alt_off_outlined),
        ),
      ],
    );
  }
}

class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  final JoinedDateSort value;
  final ValueChanged<JoinedDateSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: DropdownButtonFormField<JoinedDateSort>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          prefixIcon: Icon(Icons.sort),
        ),
        items: const [
          DropdownMenuItem(
            value: JoinedDateSort.newestFirst,
            child: Text('Newest first'),
          ),
          DropdownMenuItem(
            value: JoinedDateSort.oldestFirst,
            child: Text('Oldest first'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.value,
    required this.hint,
    required this.items,
    required this.labelFor,
    required this.onChanged,
  });

  final double width;
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T value) labelFor;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        hint: Text(hint),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text('All $hint'),
          ),
          for (final item in items)
            DropdownMenuItem<T?>(
              value: item,
              child: Text(
                labelFor(item),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _UsersBody extends StatelessWidget {
  const _UsersBody({required this.controller});

  final UsersController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading && controller.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final errorMessage = controller.errorMessage;
    if (errorMessage != null) {
      return _UsersMessage(
        icon: Icons.error_outline,
        title: errorMessage,
        action: FilledButton.icon(
          onPressed: controller.loadUsers,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      );
    }

    if (controller.users.isEmpty) {
      return const _UsersMessage(
        icon: Icons.people_alt_outlined,
        title: 'No users found.',
      );
    }

    final users = controller.filteredUsers;
    if (users.isEmpty) {
      return _UsersMessage(
        icon: Icons.filter_alt_off_outlined,
        title: 'No users match the current filters.',
        action: FilledButton.icon(
          onPressed: controller.clearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Clear filters'),
        ),
      );
    }

    return Column(
      children: [
        const _UsersTableHeader(),
        Expanded(
          child: ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _UserRow(
                user: users[index],
                isUpdatingStatus: controller.isUpdatingStatus,
                onStatusChanged: (isActive) {
                  controller.updateUserActiveStatus(
                    user: users[index],
                    isActive: isActive,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UsersTableHeader extends StatelessWidget {
  const _UsersTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF0F4F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderText('User')),
          Expanded(flex: 2, child: _HeaderText('Status')),
          Expanded(flex: 2, child: _HeaderText('Role')),
          Expanded(flex: 2, child: _HeaderText('Gender')),
          Expanded(flex: 2, child: _HeaderText('Phone')),
          Expanded(flex: 2, child: _HeaderText('Joined')),
          SizedBox(width: 130, child: _HeaderText('Action')),
        ],
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

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isUpdatingStatus,
    required this.onStatusChanged,
  });

  final AdminUser user;
  final bool isUpdatingStatus;
  final ValueChanged<bool> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  _UserAvatar(user: user),
                  const SizedBox(width: 12),
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
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user.shortId,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF66736F),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _StatusChip(isActive: user.isActive)),
            Expanded(flex: 2, child: _RoleChip(role: user.role)),
            Expanded(flex: 2, child: _CellText(user.gender ?? '-')),
            Expanded(flex: 2, child: _CellText(user.phoneNo ?? '-')),
            Expanded(flex: 2, child: _CellText(_formatDate(user.createdAt))),
            SizedBox(
              width: 130,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: isUpdatingStatus
                      ? null
                      : () => onStatusChanged(!user.isActive),
                  style: TextButton.styleFrom(
                    foregroundColor: user.isActive
                        ? Theme.of(context).colorScheme.error
                        : const Color(0xFF1F7A64),
                  ),
                  icon: Icon(
                    user.isActive
                        ? Icons.block_outlined
                        : Icons.check_circle_outline,
                  ),
                  label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
              ),
            ),
          ],
        ),
      ),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;

    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFBFE8D8),
      backgroundImage:
          avatarUrl == null || avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
      child: avatarUrl == null || avatarUrl.isEmpty
          ? const Icon(
              Icons.person_outline,
              color: Color(0xFF14211D),
              size: 21,
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F3EF) : const Color(0xFFF4EDEA),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            isActive ? 'Active' : 'Deactivated',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? const Color(0xFF1F7A64) : const Color(0xFF8A4B38),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFFE8F3EF) : const Color(0xFFF0F4F2),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            role,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isAdmin ? const Color(0xFF1F7A64) : const Color(0xFF66736F),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
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
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF3A4541),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _UsersMessage extends StatelessWidget {
  const _UsersMessage({
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF66736F), size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF66736F),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}
