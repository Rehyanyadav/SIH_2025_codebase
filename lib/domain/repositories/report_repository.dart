// Abstract repository for report operations
import '../entities/report_entity.dart';

abstract class ReportRepository {
  Future<List<ReportEntity>> getReportsForUser(String userId);
  Future<List<ReportEntity>> getAllReports();
}
