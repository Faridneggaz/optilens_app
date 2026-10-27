import '../../core/network/api_client.dart';
import '../../domain/entities/activity_report.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/activity_report_repository.dart';
import '../mappers/activity_report_mappers.dart';

class ActivityReportRepositoryImpl implements ActivityReportRepository {
  ActivityReportRepositoryImpl(this._api);
  final ApiClient _api;
  Map<String, dynamic> _message(Map<String, dynamic> json) {
    final message = _api.unwrap(json);
    if (message is! Map) {
      throw const RepositoryException('Invalid Activity Report response');
    }
    return Map<String, dynamic>.from(message);
  }

  @override
  Future<ActivityReportList> list({
    required String token,
    String search = '',
    String type = '',
    String fromDate = '',
    String toDate = '',
    int offset = 0,
  }) async => ActivityReportMapper.list(
    _message(
      await _api.getMobile(
        'get_activity_reports',
        attachToken: false,
        query: {
          'token': token,
          'search_text': search,
          'report_type': type,
          'from_date': fromDate,
          'to_date': toDate,
          'offset': '$offset',
          'limit': '20',
        },
      ),
    ),
  );
  @override
  Future<ActivityReportResult> detail({
    required String token,
    required String name,
  }) async => ActivityReportMapper.result(
    _message(
      await _api.getMobile(
        'get_activity_report',
        attachToken: false,
        query: {'token': token, 'name': name},
      ),
    ),
  );
  @override
  Future<ActivityReportResult> save({
    required String token,
    required ActivityReport report,
  }) async => ActivityReportMapper.result(
    _message(
      await _api.postMobile(
        report.name.isEmpty
            ? 'create_activity_report'
            : 'update_activity_report',
        attachToken: false,
        body: {
          'token': token,
          if (report.name.isNotEmpty) 'name': report.name,
          if (report.name.isNotEmpty) 'modified': report.modified,
          'report': ActivityReportMapper.input(report),
        },
      ),
    ),
  );
  @override
  Future<ActivityReportOptions> options({
    required String token,
    String kind = 'metadata',
    String search = '',
  }) async => ActivityReportMapper.options(
    _message(
      await _api.getMobile(
        'get_activity_report_options',
        attachToken: false,
        query: {
          'token': token,
          'kind': kind,
          'search_text': search,
          'limit': '30',
        },
      ),
    ),
  );
}
