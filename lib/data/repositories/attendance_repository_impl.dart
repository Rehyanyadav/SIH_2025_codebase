// Attendance repository implementation
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_data_source.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceDataSource dataSource;
  AttendanceRepositoryImpl(this.dataSource);

  @override
  Future<void> markAttendance(AttendanceEntity attendance) => dataSource.markAttendance(attendance);

  @override
  Future<List<AttendanceEntity>> getAttendanceForUser(String userId) async {
    // Implement using dataSource
    throw UnimplementedError();
  }

  @override
  Future<List<AttendanceEntity>> getAllAttendance() async {
    // Implement using dataSource
    throw UnimplementedError();
  }
}
