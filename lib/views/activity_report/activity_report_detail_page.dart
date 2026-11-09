import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/activity_report.dart';
import '../../presentation/controllers/activity_report_detail_controller.dart';
import '../../widgets/activity_report/report_widgets.dart';

class ActivityReportDetailPage extends StatelessWidget {
  const ActivityReportDetailPage({super.key});
  Future<void> _edit(ActivityReportDetailController c) async {
    final result = await Get.toNamed(
      AppRoutes.activityReportForm,
      arguments: {'name': c.report.value!.name},
    );
    if (result is ActivityReportResult && !result.canRead) {
      Get.back();
      return;
    }
    if (!c.isClosed) c.load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ActivityReportDetailController>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Text('ar_detail'.tr),
        backgroundColor: Colors.white,
        actions: [
          Obx(
            () => c.canWrite.value
                ? IconButton(
                    tooltip: 'ar_edit'.tr,
                    onPressed: () => _edit(c),
                    icon: const Icon(Icons.edit_outlined),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Obx(() {
        if (c.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final r = c.report.value;
        if (r == null) {
          return SingleChildScrollView(
            child: ReportErrorPanel(
              message: c.error.value.isEmpty
                  ? 'ar_not_found'.tr
                  : c.error.value,
              retry: c.load,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: c.load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ReportSection(
                title: r.title,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      Text(
                        reportTypeLabel(r.type),
                        style: const TextStyle(color: AppColors.primaryDark),
                      ),
                      if (r.date.isNotEmpty) Text(r.date),
                    ],
                  ),
                  if (r.process.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text('${'ar_process'.tr} : ${r.process}'),
                    ),
                ],
              ),
              ReportSection(title: 'ar_done'.tr, children: _lines(r.done)),
              ReportSection(title: 'ar_issues'.tr, children: _lines(r.issues)),
              ReportSection(
                title: 'ar_actions'.tr,
                helper: 'ar_action_status_help'.tr,
                children: r.actions.isEmpty
                    ? [
                        Text(
                          'ar_none'.tr,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ]
                    : r.actions
                          .map(
                            (a) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      ReportStatus(value: a.status),
                                      if (a.responsibleEmployee.isNotEmpty)
                                        Text(
                                          a.responsibleName.isEmpty
                                              ? a.responsibleEmployee
                                              : a.responsibleName,
                                          style: const TextStyle(
                                            color: AppColors.body,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (a.deadline.isNotEmpty)
                                        Text(
                                          a.deadline,
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (a.taskLink.isNotEmpty)
                                    a.canReadTask
                                        ? TextButton.icon(
                                            onPressed: () => Get.toNamed(
                                              AppRoutes.taskDetail,
                                              arguments: {'name': a.taskLink},
                                            ),
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              size: 16,
                                            ),
                                            label: Text(
                                              a.taskSubject.isEmpty
                                                  ? a.taskLink
                                                  : a.taskSubject,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              '${a.taskLink} · ${'ar_task_unavailable'.tr}',
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
              ),
              if (r.isWeekly)
                Card(
                  color: Colors.white,
                  elevation: 0,
                  child: ExpansionTile(
                    title: Text(
                      '${'ar_participants'.tr} (${r.participants.length})',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ar_attendance_help'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      ...r.participants.map(
                        (p) => ListTile(
                          title: Text(p.employeeName),
                          trailing: Text(
                            (p.present ? 'ar_present' : 'ar_absent').tr,
                            style: TextStyle(
                              color: p.present
                                  ? AppColors.primaryDark
                                  : AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _lines(List<ReportLine> lines) => lines.isEmpty
      ? [Text('ar_none'.tr, style: const TextStyle(color: AppColors.muted))]
      : lines
            .map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '• ${l.description}',
                  style: const TextStyle(height: 1.5, color: AppColors.body),
                ),
              ),
            )
            .toList();
}
