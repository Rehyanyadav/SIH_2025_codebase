// Use case for marking attendance
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class MarkAttendanceUseCase {
  final AttendanceRepository repository;
  MarkAttendanceUseCase(this.repository);

  Future<void> call(AttendanceEntity attendance) async {
    await repository.markAttendance(attendance);
  }
}
