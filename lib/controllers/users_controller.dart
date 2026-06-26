import 'package:flutter/foundation.dart';

import '../models/admin_user.dart';
import '../services/users_service.dart';

enum JoinedDateSort {
  newestFirst,
  oldestFirst,
}

class UsersController extends ChangeNotifier {
  UsersController({UsersService? usersService})
      : _usersService = usersService ?? UsersService();

  final UsersService _usersService;

  bool _isLoading = false;
  bool _isUpdatingStatus = false;
  String? _errorMessage;
  List<AdminUser> _users = const [];
  String _searchQuery = '';
  String? _roleFilter;
  String? _genderFilter;
  int? _joinedYearFilter;
  JoinedDateSort _joinedDateSort = JoinedDateSort.newestFirst;

  bool get isLoading => _isLoading;
  bool get isUpdatingStatus => _isUpdatingStatus;
  String? get errorMessage => _errorMessage;
  List<AdminUser> get users => _users;
  String get searchQuery => _searchQuery;
  String? get roleFilter => _roleFilter;
  String? get genderFilter => _genderFilter;
  int? get joinedYearFilter => _joinedYearFilter;
  JoinedDateSort get joinedDateSort => _joinedDateSort;

  List<String> get roleOptions {
    final roles = {
      for (final user in _users)
        if (user.role.trim().isNotEmpty) user.role,
    }.toList();

    roles.sort();
    return roles;
  }

  List<String> get genderOptions {
    final genders = {
      for (final user in _users)
        if ((user.gender ?? '').trim().isNotEmpty) user.gender!.trim(),
    }.toList();

    genders.sort();
    return genders;
  }

  List<int> get joinedYearOptions {
    final years = {
      for (final user in _users)
        if (user.createdAt != null) user.createdAt!.year,
    }.toList();

    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  List<AdminUser> get filteredUsers {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = _users.where((user) {
      if (_roleFilter != null && user.role != _roleFilter) {
        return false;
      }

      if (_genderFilter != null && user.gender?.trim() != _genderFilter) {
        return false;
      }

      if (_joinedYearFilter != null && user.createdAt?.year != _joinedYearFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return _searchableTextFor(user).contains(query);
    }).toList();

    filtered.sort((a, b) {
      final comparison = _compareJoinedDate(a.createdAt, b.createdAt);
      return _joinedDateSort == JoinedDateSort.newestFirst
          ? comparison
          : -comparison;
    });

    return filtered;
  }

  bool get hasActiveFilters {
    return _searchQuery.trim().isNotEmpty ||
        _roleFilter != null ||
        _genderFilter != null ||
        _joinedYearFilter != null;
  }

  void updateSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void updateRoleFilter(String? value) {
    _roleFilter = value;
    notifyListeners();
  }

  void updateGenderFilter(String? value) {
    _genderFilter = value;
    notifyListeners();
  }

  void updateJoinedYearFilter(int? value) {
    _joinedYearFilter = value;
    notifyListeners();
  }

  void updateJoinedDateSort(JoinedDateSort value) {
    _joinedDateSort = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _roleFilter = null;
    _genderFilter = null;
    _joinedYearFilter = null;
    notifyListeners();
  }

  int _compareJoinedDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) {
      return 0;
    }
    if (a == null) {
      return 1;
    }
    if (b == null) {
      return -1;
    }

    return b.compareTo(a);
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _usersService.fetchUsers();
    } catch (_) {
      _errorMessage = 'Unable to load users.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserActiveStatus({
    required AdminUser user,
    required bool isActive,
  }) async {
    _isUpdatingStatus = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _usersService.updateUserActiveStatus(
        userId: user.id,
        isActive: isActive,
      );
      await loadUsers();
    } catch (_) {
      _errorMessage = 'Unable to update user status.';
    } finally {
      _isUpdatingStatus = false;
      notifyListeners();
    }
  }

  String _searchableTextFor(AdminUser user) {
    return [
      user.displayName,
      user.id,
      user.shortId,
      user.role,
      user.isActive ? 'active' : 'deactivated',
      user.gender ?? '',
      _formatDate(user.createdAt),
      user.createdAt?.year.toString() ?? '',
    ].join(' ').toLowerCase();
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }
}
