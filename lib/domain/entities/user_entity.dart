// User entity for domain layer
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role; // now a string: 'admin', 'teacher', 'student'
  final String? photoBase64; // for students only
  final String? barcode; // for students only

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photoBase64,
    this.barcode,
  });

  @override
  List<Object?> get props => [id, name, email, role, photoBase64, barcode];
}
