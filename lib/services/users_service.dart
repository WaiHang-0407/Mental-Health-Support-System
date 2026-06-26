import '../models/admin_user.dart';
import '../repositories/users_repository.dart';

class UsersService {
  UsersService({UsersRepository? usersRepository})
      : _usersRepository = usersRepository ?? UsersRepository();

  final UsersRepository _usersRepository;

  Future<List<AdminUser>> fetchUsers() {
    return _usersRepository.fetchUsers();
  }

  Future<void> updateUserActiveStatus({
    required String userId,
    required bool isActive,
  }) {
    return _usersRepository.updateUserActiveStatus(
      userId: userId,
      isActive: isActive,
    );
  }
}
