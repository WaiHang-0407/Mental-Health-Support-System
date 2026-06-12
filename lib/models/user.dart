// models/user.dart
class UserModel {
  final String id;
  final String role;

  UserModel({required this.id, required this.role});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(id: map['id'], role: map['role']);
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'role': role};
  }
}