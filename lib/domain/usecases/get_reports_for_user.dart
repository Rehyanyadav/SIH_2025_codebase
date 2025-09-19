// Use case for getting reports for a user
import '../entities/report_entity.dart';
import '../repositories/report_repository.dart';

class GetReportsForUserUseCase {
  final ReportRepository repository;
  GetReportsForUserUseCase(this.repository);

  Future<List<ReportEntity>> call(String userId) async {
    return await repository.getReportsForUser(userId);
  }
}
