// Report entity for domain layer
import 'package:equatable/equatable.dart';

class ReportEntity extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final int presentCount;
  final int absentCount;

  const ReportEntity({
    required this.id,
    required this.userId,
    required this.date,
    required this.presentCount,
    required this.absentCount,
  });

  @override
  List<Object?> get props => [id, userId, date, presentCount, absentCount];
}
