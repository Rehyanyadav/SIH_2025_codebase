import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import '../domain/entities/user_entity.dart';

Future<void> seedTestData() async {
  final firestore = FirebaseService.firestore;
  final auth = FirebaseAuth.instance;
  // Add demo teachers
  final teachers = [
    UserEntity(
      id: 't1',
      name: 'Alice Sharma',
      email: 'alice@school.com',
      role: 'teacher',
    ),
    UserEntity(
      id: 't2',
      name: 'Rahul Singh',
      email: 'rahul@school.com',
      role: 'teacher',
    ),
  ];
  for (final t in teachers) {
    await firestore.collection('users').doc(t.id).set({
      'name': t.name,
      'email': t.email,
      'role': t.role,
    });
  }
  // Add demo attendance records (slot-wise)
  final attendance = [
    {
      'teacherId': 't1',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'slot': 'before_class',
      'present': 25,
      'absent': 5,
    },
    {
      'teacherId': 't1',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'slot': 'after_mid_day_meal',
      'present': 23,
      'absent': 7,
    },
    {
      'teacherId': 't2',
      'date': DateTime.now(),
      'slot': 'before_class',
      'present': 30,
      'absent': 0,
    },
    {
      'teacherId': 't2',
      'date': DateTime.now(),
      'slot': 'after_mid_day_meal',
      'present': 29,
      'absent': 1,
    },
  ];
  for (final a in attendance) {
    await firestore.collection('attendance').add({
      'teacherId': a['teacherId'],
      'date': (a['date'] as DateTime).toIso8601String(),
      'slot': a['slot'],
      'present': a['present'],
      'absent': a['absent'],
    });
  }
  // Add demo admin (create in Auth and Firestore)
  try {
    final adminCredential = await auth.createUserWithEmailAndPassword(
      email: 'admin@school.com',
      password: 'admin123',
    );
    await firestore.collection('users').doc(adminCredential.user!.uid).set({
      'name': 'Admin User',
      'email': 'admin@school.com',
      'role': 'admin',
    });
  } catch (e) {
    // If already exists, skip
  }
}
