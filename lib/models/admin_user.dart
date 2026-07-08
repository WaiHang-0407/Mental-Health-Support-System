class AdminUser {
  const AdminUser({
    required this.id,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.name,
    this.gender,
    this.phoneNo,
    this.avatarUrl,
    this.isSubscribed = false,
    this.subscriptionExpiresAt,
  });

  final String id;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final String? name;
  final String? gender;
  final String? phoneNo;
  final String? avatarUrl;
  final bool isSubscribed;
  final DateTime? subscriptionExpiresAt;

  String get displayName {
    final value = name?.trim();
    return value == null || value.isEmpty ? 'Unnamed user' : value;
  }

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);

  factory AdminUser.fromRows({
    required Map<String, dynamic> user,
    Map<String, dynamic>? patient,
    Map<String, dynamic>? subscription,
  }) {
    return AdminUser(
      id: user['id'] as String,
      role: user['role'] as String? ?? 'patient',
      isActive: _parseBool(user['is_active']),
      createdAt: DateTime.tryParse(user['created_at'] as String? ?? ''),
      name: patient?['name'] as String?,
      gender: patient?['gender'] as String?,
      phoneNo: patient?['phoneno'] as String?,
      avatarUrl: patient?['avatar_url'] as String?,
      isSubscribed:
          subscription == null ? false : _parseBool(subscription['is_active']),
      subscriptionExpiresAt: DateTime.tryParse(
        subscription?['expires_at'] as String? ?? '',
      ),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return true;
  }
}
