// Abstract repository for attendance operations
import '../entities/attendance_entity.dart';

abstract class AttendanceRepository {
  Future<void> markAttendance(AttendanceEntity attendance);
  Future<List<AttendanceEntity>> getAttendanceForUser(String userId);
  Future<List<AttendanceEntity>> getAllAttendance();
}
