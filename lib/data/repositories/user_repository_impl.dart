// User repository implementation
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;
  UserRepositoryImpl(this.dataSource);

  @override
  Future<UserEntity?> getUserById(String id) => dataSource.getUserById(id);

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final snapshot = await dataSource.firestore.collection('users').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserEntity(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        role: data['role'] as String,
      );
    }).toList();
  }

  @override
  Future<void> addUser(UserEntity user) async {
    await dataSource.addUser(user);
  }

  @override
  Future<void> updateUser(UserEntity user) async {
    // Implement using dataSource
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String id) async {
    // Implement using dataSource
    throw UnimplementedError();
  }
}
