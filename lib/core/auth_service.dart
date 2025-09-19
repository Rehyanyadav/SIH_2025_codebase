import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../domain/entities/user_entity.dart' show UserEntity;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserEntity?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return UserEntity(
      id: user.uid,
      name: data['name'],
      email: data['email'],
      role: data['role'], // store as String
      photoBase64: data['photoBase64'],
      barcode: data['barcode'],
    );
  }

  Future<UserEntity?> registerTeacher(
    String name,
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    final userEntity = UserEntity(
      id: user.uid,
      name: name,
      email: email,
      role: 'teacher',
    );
    await _firestore.collection(AppConstants.usersCollection).doc(user.uid).set(
      {'name': name, 'email': email, 'role': 'teacher'},
    );
    return userEntity;
  }

  Future<UserEntity?> registerStudent(
    String name,
    String email,
    String password,
    String photoBase64,
    String barcode,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;
    final userEntity = UserEntity(
      id: user.uid,
      name: name,
      email: email,
      role: 'student',
      photoBase64: photoBase64,
      barcode: barcode,
    );
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set({
          'name': name,
          'email': email,
          'role': 'student',
          'photoBase64': photoBase64,
          'barcode': barcode,
        });
    return userEntity;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
