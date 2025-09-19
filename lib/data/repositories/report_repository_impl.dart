// Report repository implementation
import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/report_repository.dart';
import '../datasources/report_data_source.dart';

class ReportRepositoryImpl implements ReportRepository {
  final ReportDataSource dataSource;
  ReportRepositoryImpl(this.dataSource);

  @override
  Future<List<ReportEntity>> getReportsForUser(String userId) async {
    // Implement using dataSource
    throw UnimplementedError();
  }

  @override
  Future<List<ReportEntity>> getAllReports() async {
    // Implement using dataSource
    throw UnimplementedError();
  }
}
