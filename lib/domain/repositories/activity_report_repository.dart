import '../entities/activity_report.dart';

abstract class ActivityReportRepository {
  Future<ActivityReportList> list({
    required String token,
    String search = '',
    String type = '',
    String fromDate = '',
    String toDate = '',
    int offset = 0,
  });
  Future<ActivityReportResult> detail({
    required String token,
    required String name,
  });
  Future<ActivityReportResult> save({
    required String token,
    required ActivityReport report,
  });
  Future<ActivityReportOptions> options({
    required String token,
    String kind = 'metadata',
    String search = '',
  });
}
