import '../entities/activity_report.dart';
import '../repositories/activity_report_repository.dart';

class ActivityReportUseCases {
  ActivityReportUseCases(this._repo);
  final ActivityReportRepository _repo;
  Future<ActivityReportList> list({
    required String token,
    String search = '',
    String type = '',
    String fromDate = '',
    String toDate = '',
    int offset = 0,
  }) => _repo.list(
    token: token,
    search: search,
    type: type,
    fromDate: fromDate,
    toDate: toDate,
    offset: offset,
  );
  Future<ActivityReportResult> detail({
    required String token,
    required String name,
  }) => _repo.detail(token: token, name: name);
  Future<ActivityReportResult> save({
    required String token,
    required ActivityReport report,
  }) => _repo.save(token: token, report: report);
  Future<ActivityReportOptions> options({
    required String token,
    String kind = 'metadata',
    String search = '',
  }) => _repo.options(token: token, kind: kind, search: search);
}
