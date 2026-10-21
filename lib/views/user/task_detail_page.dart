import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../presentation/controllers/task_detail_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/task/task_form_sheet.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key});
  @override
  Widget build(BuildContext context) {
    final c = Get.find<TaskDetailController>();
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          AppHeader(title: 'nav_my_tasks'.tr, customer: null, customerCode: ''),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              final task = c.task.value;
              if (task == null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.errorMessage.value, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: c.fetchDetail,
                          child: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: c.fetchDetail,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.subject,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (task.canWrite)
                          IconButton(
                            tooltip: 'erp_task_edit'.tr,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              final saved = await showTaskForm(
                                context: context,
                                controller: Get.find<TaskController>(),
                                task: task,
                              );
                              if (saved != null) c.task.value = saved;
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(task.name),
                        TaskStatusChip(status: task.status),
                        TaskPriorityChip(priority: task.priority),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (task.descriptionText.isNotEmpty)
                      _section(
                        'task_description'.tr,
                        Text(task.descriptionText),
                      ),
                    _section(
                      'erp_task_progress'.tr,
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: (task.progress / 100).clamp(0, 1),
                          ),
                          const SizedBox(height: 6),
                          Text('${task.progress.round()}%'),
                        ],
                      ),
                    ),
                    _section(
                      'erp_task_details'.tr,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task.company.isNotEmpty)
                            Text('${'erp_task_company'.tr}: ${task.company}'),
                          if (task.project.isNotEmpty)
                            Text('${'erp_task_project'.tr}: ${task.project}'),
                          if (task.startDate.isNotEmpty)
                            Text('${'erp_task_start'.tr}: ${task.startDate}'),
                          if (task.endDate.isNotEmpty)
                            Text('${'erp_task_end'.tr}: ${task.endDate}'),
                          if (task.owner.isNotEmpty)
                            Text('${'erp_task_created_by'.tr}: ${task.owner}'),
                        ],
                      ),
                    ),
                    _section(
                      'erp_task_assignees'.tr,
                      Text(
                        task.assignees.isEmpty
                            ? 'erp_task_unassigned'.tr
                            : task.assignees
                                  .map((u) => '${u.displayName} — ${u.email}')
                                  .join('\n'),
                      ),
                    ),
                    if (task.previousAssignees.isNotEmpty)
                      _section(
                        'erp_task_previous_assignees'.tr,
                        Text(
                          task.previousAssignees
                              .map((u) => '${u.displayName} — ${u.email}')
                              .join('\n'),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        final task = c.task.value;
        if (task == null || !task.canWrite || task.allowedStatuses.isEmpty) {
          return const SizedBox.shrink();
        }
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: c.isUpdating.value
                  ? null
                  : () => _pickStatus(context, c),
              icon: c.isUpdating.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_alt),
              label: Text('erp_task_change_status'.tr),
            ),
          ),
        );
      }),
    );
  }

  Widget _section(String title, Widget child) => Card(
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );

  Future<void> _pickStatus(BuildContext context, TaskDetailController c) async {
    final task = c.task.value;
    if (task == null) return;
    final next = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.scaffold,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final status in task.allowedStatuses.where(
              (s) => s != task.status,
            ))
              ListTile(
                title: Text(taskStatusLabel(status)),
                onTap: () => Navigator.pop(context, status),
              ),
          ],
        ),
      ),
    );
    if (next == null || !context.mounted) return;
    if (next == 'Completed' || next == 'Cancelled') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(taskStatusLabel(next)),
          content: Text('erp_task_status_confirmation'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('cancel'.tr),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('confirm'.tr),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    final result = await c.changeStatus(next);
    if (!result.isSuccess && !result.isAuthHandled) {
      Get.snackbar('error'.tr, result.error ?? 'error_occurred'.tr);
    }
  }
}
