// Firestore attendance data source implementation
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../core/constants.dart';

class AttendanceDataSource {
  final FirebaseFirestore firestore;
  AttendanceDataSource(this.firestore);

  Future<void> markAttendance(AttendanceEntity attendance) async {
    await firestore.collection(AppConstants.attendanceCollection).add({
      'userId': attendance.userId,
      'date': attendance.date.toIso8601String(),
      'method': attendance.method,
    });
  }

  // Add more methods as needed
}
