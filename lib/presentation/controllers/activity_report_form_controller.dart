import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/activity_report.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/activity_report_usecases.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../utils/activity_report_feedback.dart';
import 'task_controller.dart';

class ActivityReportFormController extends GetxController {
  ActivityReportFormController({
    ActivityReportUseCases? reports,
    TaskUseCases? tasks,
    String? name,
    String Function()? tokenProvider,
  }) : _reports = reports ?? Get.find<ActivityReportUseCases>(),
       _tasks = tasks,
       _name = name ?? '',
       _tokenProvider = tokenProvider;
  final ActivityReportUseCases _reports;
  final TaskUseCases? _tasks;
  final String Function()? _tokenProvider;
  String _name;
  final draft = const ActivityReport().obs;
  final options = const ActivityReportOptions().obs;
  final titleController = TextEditingController();
  final loading = true.obs;
  final saving = false.obs;
  final dirty = false.obs;
  final canEdit = false.obs;
  final error = ''.obs;
  bool get editing => _name.isNotEmpty;
  String get token =>
      _tokenProvider?.call() ?? Get.find<SessionService>().authToken;
  bool get losesWeeklyAccess {
    if (!draft.value.isWeekly) return false;
    final employee = options.value.currentEmployee;
    return employee == null ||
        !draft.value.participants.any(
          (p) => p.employee == employee.value && p.present,
        );
  }

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is Map) {
      _name = Get.arguments['name']?.toString() ?? _name;
    }
    load();
  }

  @override
  void onClose() {
    titleController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    error.value = '';
    canEdit.value = false;
    try {
      final metadata = await _reports.options(token: token);
      ActivityReport initial;
      if (editing) {
        final detail = await _reports.detail(token: token, name: _name);
        if (!detail.canWrite || detail.report == null) {
          throw const AccessDeniedException();
        }
        initial = detail.report!;
      } else {
        if (!metadata.canCreate) throw const AccessDeniedException();
        final date = DateTime.now().toIso8601String().substring(0, 10);
        final employee = metadata.currentEmployee;
        initial = ActivityReport(
          title: '${'ar_weekly'.tr} — $date',
          date: date,
          participants: employee == null
              ? []
              : [
                  ReportParticipant(
                    employee: employee.value,
                    employeeName: employee.label,
                  ),
                ],
        );
      }
      if (isClosed) return;
      options.value = metadata;
      draft.value = initial;
      titleController.text = initial.title;
      dirty.value = false;
      canEdit.value = true;
    } catch (e) {
      if (!isClosed) error.value = activityReportError(e);
    } finally {
      if (!isClosed) loading.value = false;
    }
  }

  void change(ActivityReport value) {
    if (!canEdit.value || saving.value) return;
    draft.value = value;
    dirty.value = true;
  }

  void setType(String value) {
    final r = draft.value;
    final automatic =
        '${(r.isWeekly ? 'ar_weekly' : 'ar_monthly').tr} — ${r.date}';
    final title = !editing && r.title == automatic
        ? '${(value == 'Weekly Report' ? 'ar_weekly' : 'ar_monthly').tr} — ${r.date}'
        : r.title;
    titleController.text = title;
    change(r.copyWith(type: value, title: title));
  }

  void setDate(String value) {
    final r = draft.value;
    final automatic =
        '${(r.isWeekly ? 'ar_weekly' : 'ar_monthly').tr} — ${r.date}';
    final title = !editing && r.title == automatic
        ? '${(r.isWeekly ? 'ar_weekly' : 'ar_monthly').tr} — $value'
        : r.title;
    titleController.text = title;
    change(r.copyWith(date: value, title: title));
  }

  Future<ActivityReportOptions> searchOptions(String kind, String query) =>
      _reports.options(token: token, kind: kind, search: query);
  Future<({List<ReportOption> items, bool more})> searchTasks(
    String query,
    int offset,
  ) async {
    final result = await (_tasks ?? Get.find<TaskUseCases>()).fetchTasks(
      token: token,
      scope: 'accessible',
      status: 'All',
      searchText: query,
      offset: offset,
    );
    return (
      items: result.tasks
          .map((t) => ReportOption(value: t.name, label: t.subject))
          .toList(),
      more: result.hasMore,
    );
  }

  Future<ActivityReportResult?> save() async {
    if (!canEdit.value || saving.value) return null;
    if (draft.value.title.trim().isEmpty) {
      error.value = 'ar_title_required'.tr;
      return null;
    }
    saving.value = true;
    error.value = '';
    try {
      final result = await _reports.save(token: token, report: draft.value);
      if (isClosed) return result;
      dirty.value = false;
      if (Get.isRegistered<TaskController>()) {
        unawaited(Get.find<TaskController>().onRefresh());
      }
      return result;
    } catch (e) {
      if (!isClosed) error.value = activityReportError(e);
      return null;
    } finally {
      if (!isClosed) saving.value = false;
    }
  }
}
