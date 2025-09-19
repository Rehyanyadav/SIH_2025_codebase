// Attendance entity for domain layer
import 'package:equatable/equatable.dart';

class AttendanceEntity extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final String method; // 'barcode' or 'face'

  const AttendanceEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.method,
  });

  @override
  List<Object?> get props => [id, userId, date, method];
}
