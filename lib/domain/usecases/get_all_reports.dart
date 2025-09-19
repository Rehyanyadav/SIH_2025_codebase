// Use case for getting all reports
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetAllReportsUseCase {
  final ReportRepository repository;
  GetAllReportsUseCase(this.repository);

  Future<List<ReportEntity>> call() async {
    return await repository.getAllReports();
  }
}
