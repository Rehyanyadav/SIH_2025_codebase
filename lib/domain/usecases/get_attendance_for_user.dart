// Use case for getting attendance for a user
import '../entities/attendance_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceForUserUseCase {
  final AttendanceRepository repository;
  GetAttendanceForUserUseCase(this.repository);

  Future<List<AttendanceEntity>> call(String userId) async {
    return await repository.getAttendanceForUser(userId);
  }
}
