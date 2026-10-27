import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:optilens/core/network/api_client.dart';
import 'package:optilens/data/repositories/activity_report_repository.dart';
import 'package:optilens/data/mappers/activity_report_mappers.dart';
import 'package:optilens/domain/entities/activity_report.dart';
import 'package:optilens/domain/failures/failures.dart';

http.Response reply(Map<String, dynamic> m) => http.Response(
  jsonEncode({'message': m}),
  200,
  headers: {'content-type': 'application/json'},
);
void main() {
  test(
    'report list passes session, filters and page to native report API',
    () async {
      final repo = ActivityReportRepositoryImpl(
        ApiClient(
          httpClient: MockClient((r) async {
            expect(r.method, 'GET');
            expect(r.body, isEmpty);
            expect(r.url.path, endsWith('mobile_app.api.get_activity_reports'));
            expect(r.url.queryParameters, containsPair('token', 'sid'));
            expect(
              r.url.queryParameters,
              containsPair('report_type', 'Weekly Report'),
            );
            expect(
              r.url.queryParameters,
              containsPair('from_date', '2026-10-01'),
            );
            expect(r.url.queryParameters, containsPair('offset', '20'));
            return reply({
              'reports': [
                {
                  'name': 'AR-1',
                  'title': 'Weekly inventory',
                  'doc_type': 'Weekly Report',
                  'action_count': 3,
                },
              ],
              'total_items': 42,
              'has_more': true,
              'can_create': false,
            });
          }),
        ),
      );
      final list = await repo.list(
        token: 'sid',
        type: 'Weekly Report',
        fromDate: '2026-10-01',
        offset: 20,
      );
      expect(list.total, 42);
      expect(list.reports.single.actionCount, 3);
      expect(list.hasMore, isTrue);
      expect(list.canCreate, isFalse);
    },
  );
  test(
    'save preserves child IDs and only sends editable fields and version',
    () async {
      final repo = ActivityReportRepositoryImpl(
        ApiClient(
          httpClient: MockClient((r) async {
            expect(r.url.path, endsWith('update_activity_report'));
            expect(r.method, 'POST');
            final body = jsonDecode(r.body) as Map;
            expect(body['modified'], 'v1');
            expect(body['token'], 'sid');
            final payload = body['report'] as Map;
            expect(payload.containsKey('owner'), isFalse);
            expect(payload.containsKey('can_write'), isFalse);
            expect(payload['done_list'][0], {
              'name': 'ROW-1',
              'description': 'Counted lenses',
            });
            expect(payload['attendance_list'][0]['present'], 0);
            expect(payload['task_list'][0]['status'], 'In Progress');
            return reply({
              'success': true,
              'can_read': false,
              'can_write': false,
              'report': null,
            });
          }),
        ),
      );
      final result = await repo.save(
        token: 'sid',
        report: const ActivityReport(
          name: 'AR-1',
          modified: 'v1',
          title: 'Review',
          owner: 'somebody',
          done: [ReportLine(name: 'ROW-1', description: 'Counted lenses')],
          participants: [
            ReportParticipant(
              name: 'ATT-1',
              employee: 'EMP-1',
              employeeName: 'Alice',
              present: false,
            ),
          ],
          actions: [
            ReportAction(
              description: 'Review stock',
              taskLink: 'TASK-1',
              status: 'In Progress',
            ),
          ],
        ),
      );
      expect(result.canRead, isFalse);
      expect(result.report, isNull);
    },
  );
  test(
    'creation selects the create endpoint and unwraps native fields',
    () async {
      final repo = ActivityReportRepositoryImpl(
        ApiClient(
          httpClient: MockClient((r) async {
            expect(r.url.path, endsWith('create_activity_report'));
            final body = jsonDecode(r.body) as Map;
            expect(body.containsKey('modified'), isFalse);
            expect(body.containsKey('name'), isFalse);
            return reply({
              'can_read': true,
              'can_write': true,
              'report': {
                'name': 'AR-1',
                'title': 'Review',
                'doc_type': 'Monthly Report',
                'modified': 'v1',
              },
            });
          }),
        ),
      );
      final result = await repo.save(
        token: 'sid',
        report: const ActivityReport(title: 'Review', type: 'Monthly Report'),
      );
      expect(result.report!.type, 'Monthly Report');
      expect(result.canWrite, isTrue);
    },
  );
  test(
    'mapper retains both report status and permission to open a linked Task',
    () {
      final r = ActivityReportMapper.report({
        'name': 'AR',
        'doc_type': 'Weekly Report',
        'attendance_list': [
          {'employee': 'EMP-1', 'employee_name': 'Alice', 'present': 1},
        ],
        'task_list': [
          {
            'description': 'Review',
            'task_link': 'TASK-1',
            'status': 'In Progress',
            'can_read_task': false,
          },
        ],
      });
      expect(r.participants.single.present, isTrue);
      expect(r.actions.single.canReadTask, isFalse);
      expect(r.actions.single.status, 'In Progress');
    },
  );
  test(
    'permission errors are never parsed as an empty successful report list',
    () async {
      final repo = ActivityReportRepositoryImpl(
        ApiClient(
          httpClient: MockClient(
            (r) async => reply({'error': 'Access denied'}),
          ),
        ),
      );
      await expectLater(
        repo.list(token: 'sid'),
        throwsA(isA<AccessDeniedException>()),
      );
    },
  );
}
