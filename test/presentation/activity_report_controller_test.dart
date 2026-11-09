import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:optilens/domain/entities/activity_report.dart';
import 'package:optilens/domain/repositories/activity_report_repository.dart';
import 'package:optilens/domain/usecases/activity_report_usecases.dart';
import 'package:optilens/domain/failures/failures.dart';
import 'package:optilens/presentation/controllers/activity_report_list_controller.dart';
import 'package:optilens/presentation/controllers/activity_report_form_controller.dart';
import 'package:optilens/presentation/controllers/activity_report_detail_controller.dart';

const sampleReport = ActivityReport(
  name: 'AR-1',
  title: 'Bilan de la semaine',
  actionCount: 1,
  date: '2026-10-27',
  modified: 'version-1',
  done: [
    ReportLine(name: 'ROW-1', description: 'Inventaire des verres terminé'),
  ],
  issues: [ReportLine(description: 'Livraison à suivre')],
  actions: [
    ReportAction(
      description: 'Vérifier la commande',
      responsibleEmployee: 'EMP-1',
      responsibleName: 'Alice',
      status: 'In Progress',
    ),
  ],
  participants: [ReportParticipant(employee: 'EMP-1', employeeName: 'Alice')],
);

class FakeReports implements ActivityReportRepository {
  bool canCreate = true, canWrite = true, loseAccess = false;
  Object? saveError;
  int saves = 0;
  final pending = <Future<ActivityReportList>>[];
  final offsets = <int>[];
  ActivityReport? saved;
  @override
  Future<ActivityReportList> list({
    required String token,
    String search = '',
    String type = '',
    String fromDate = '',
    String toDate = '',
    int offset = 0,
  }) async {
    offsets.add(offset);
    return pending.isEmpty
        ? ActivityReportList(
            reports: [sampleReport],
            total: 1,
            canCreate: canCreate,
          )
        : pending.removeAt(0);
  }

  @override
  Future<ActivityReportResult> detail({
    required String token,
    required String name,
  }) async => ActivityReportResult(
    report: sampleReport,
    canRead: true,
    canWrite: canWrite,
  );
  @override
  Future<ActivityReportResult> save({
    required String token,
    required ActivityReport report,
  }) async {
    saves++;
    saved = report;
    if (saveError != null) throw saveError!;
    return ActivityReportResult(
      report: loseAccess ? null : report,
      canRead: !loseAccess,
      canWrite: !loseAccess,
    );
  }

  @override
  Future<ActivityReportOptions> options({
    required String token,
    String kind = 'metadata',
    String search = '',
  }) async => ActivityReportOptions(
    canCreate: canCreate,
    types: const ['Weekly Report', 'Monthly Report'],
    statuses: const ['Open', 'In Progress', 'Completed', 'Cancelled'],
    currentEmployee: const ReportOption(value: 'EMP-1', label: 'Alice'),
    items: const [
      ReportOption(value: 'EMP-1', label: 'Alice'),
      ReportOption(value: 'EMP-2', label: 'Bob'),
    ],
  );
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);
  test('late report responses cannot overwrite the latest filters', () async {
    final old = Completer<ActivityReportList>();
    final latest = Completer<ActivityReportList>();
    final repo = FakeReports()..pending.addAll([old.future, latest.future]);
    final c = ActivityReportListController(
      reports: ActivityReportUseCases(repo),
      tokenProvider: () => 'sid',
    );
    final first = c.refreshReports();
    c.type.value = 'Monthly Report';
    final second = c.refreshReports();
    latest.complete(
      const ActivityReportList(
        reports: [ActivityReport(name: 'LATEST')],
        total: 1,
      ),
    );
    await second;
    old.complete(
      const ActivityReportList(
        reports: [ActivityReport(name: 'OLD')],
        total: 99,
      ),
    );
    await first;
    expect(c.items.single.name, 'LATEST');
    expect(c.total.value, 1);
    c.onClose();
  });
  test('pagination uses the server total and offset', () async {
    final repo = FakeReports()
      ..pending.addAll([
        Future.value(
          const ActivityReportList(
            reports: [ActivityReport(name: '1')],
            total: 30,
            hasMore: true,
          ),
        ),
        Future.value(
          const ActivityReportList(
            reports: [ActivityReport(name: '2')],
            total: 30,
          ),
        ),
      ]);
    final c = ActivityReportListController(
      reports: ActivityReportUseCases(repo),
      tokenProvider: () => 'sid',
    );
    await c.refreshReports();
    await c.loadMore();
    expect(repo.offsets, [0, 1]);
    expect(c.total.value, 30);
    expect(c.items.length, 2);
    c.onClose();
  });
  test(
    'new report includes the current employee; failed save preserves input',
    () async {
      final repo = FakeReports()
        ..saveError = const RepositoryException('Network error');
      final c = ActivityReportFormController(
        reports: ActivityReportUseCases(repo),
        tokenProvider: () => 'sid',
      );
      await c.load();
      expect(c.draft.value.participants.single.employee, 'EMP-1');
      expect(c.draft.value.participants.single.present, isTrue);
      c.titleController.text = 'My draft';
      c.change(
        c.draft.value.copyWith(
          title: 'My draft',
          done: const [ReportLine(description: 'Done')],
        ),
      );
      expect(await c.save(), isNull);
      expect(c.dirty.value, isTrue);
      expect(c.titleController.text, 'My draft');
      expect(c.draft.value.done.single.description, 'Done');
      repo.saveError = null;
      repo.loseAccess = true;
      expect((await c.save())!.canRead, isFalse);
      expect(c.dirty.value, isFalse);
      c.onClose();
    },
  );
  test(
    'read-only users cannot open an editable draft or send a write',
    () async {
      final repo = FakeReports()..canWrite = false;
      final c = ActivityReportFormController(
        reports: ActivityReportUseCases(repo),
        name: 'AR-1',
        tokenProvider: () => 'sid',
      );
      await c.load();
      expect(c.canEdit.value, isFalse);
      expect(await c.save(), isNull);
      expect(repo.saves, 0);
      c.onClose();
      final detail = ActivityReportDetailController(
        reports: ActivityReportUseCases(repo),
        name: 'AR-1',
        tokenProvider: () => 'sid',
      );
      await detail.load();
      expect(detail.canWrite.value, isFalse);
      detail.onClose();
    },
  );
  test(
    'editing retains child IDs and version; loss-of-access warning follows presence',
    () async {
      final repo = FakeReports();
      final c = ActivityReportFormController(
        reports: ActivityReportUseCases(repo),
        name: 'AR-1',
        tokenProvider: () => 'sid',
      );
      await c.load();
      expect(c.losesWeeklyAccess, isFalse);
      c.change(c.draft.value.copyWith(participants: const []));
      expect(c.losesWeeklyAccess, isTrue);
      await c.save();
      expect(repo.saved!.modified, 'version-1');
      expect(repo.saved!.done.single.name, 'ROW-1');
      c.onClose();
    },
  );
}
