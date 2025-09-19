// Firestore user data source implementation
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../core/constants.dart';

class UserDataSource {
  final FirebaseFirestore firestore;
  UserDataSource(this.firestore);

  Future<UserEntity?> getUserById(String id) async {
    final doc = await firestore
        .collection(AppConstants.usersCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return UserEntity(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'] as String,
    );
  }

  Future<UserEntity?> getUserByEmail(String email) async {
    final query = await firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    final data = doc.data();
    return UserEntity(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'] as String,
    );
  }

  Future<void> addUser(UserEntity user) async {
    await firestore.collection(AppConstants.usersCollection).doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'role': user.role,
    });
  }

  // Add more methods as needed
}
