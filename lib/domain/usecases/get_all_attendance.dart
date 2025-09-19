// Use case for getting all attendance
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAllAttendanceUseCase {
  final AttendanceRepository repository;
  GetAllAttendanceUseCase(this.repository);

  Future<List<AttendanceEntity>> call() async {
    return await repository.getAllAttendance();
  }
}
