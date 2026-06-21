// models/user.dart
class UserModel {
  final String id;
  final String role;
  final DateTime? createdAt;

  UserModel({required this.id, required this.role, this.createdAt});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      role: map['role'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
