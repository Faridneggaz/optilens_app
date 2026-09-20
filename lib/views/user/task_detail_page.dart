import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/task_detail_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/material_request/mr_form_widgets.dart';
import '../../widgets/stock/document_ui.dart';
import '../../widgets/task/task_card.dart';

class TaskDetailPage extends StatelessWidget {
  const TaskDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TaskDetailController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Obx(() {
        if (c.isLoading.value) {
          return const Scaffold(
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: CircularProgressIndicator(color: Colors.teal)),
          );
        }

        final task = c.task.value;
        if (task == null) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldTint,
            body: Center(child: Text('failed_load_task_detail'.tr)),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.scaffoldTint,
          body: Column(
            children: [
              AppHeader(
                title: task.name,
                customer: null,
                customerCode: '',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: c.fetchDetail,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'nav_my_tasks'.tr,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          MrStatusChip(status: task.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MrSectionCard(
                        title: 'task_description'.tr,
                        children: [
                          Text(
                            task.description.isNotEmpty
                                ? task.description
                                : '—',
                            style: const TextStyle(
                              color: AppColors.body,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                      MrSectionCard(
                        title: 'mr_details_section'.tr,
                        children: [
                          MrInfoRow(
                            label: 'task_priority'.tr,
                            value: task.priority,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TaskPriorityChip(priority: task.priority),
                              if (task.isOverdue) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'task_overdue'.tr,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 12),
                          MrInfoRow(
                            label: 'task_date'.tr,
                            value: task.date,
                          ),
                          MrInfoRow(
                            label: 'task_assigned_by'.tr,
                            value: task.assignedBy.isEmpty
                                ? '—'
                                : task.assignedBy,
                          ),
                          if (task.allocatedTo.isNotEmpty)
                            MrInfoRow(
                              label: 'task_allocated_to'.tr,
                              value: task.allocatedTo,
                            ),
                        ],
                      ),
                      if (task.hasReference)
                        MrSectionCard(
                          title: 'task_reference'.tr,
                          children: [
                            InkWell(
                              onTap: c.canOpenReference
                                  ? c.openReference
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 18,
                                      color: c.canOpenReference
                                          ? AppColors.primary
                                          : AppColors.muted,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${task.referenceType} / ${task.referenceName}',
                                        style: TextStyle(
                                          color: c.canOpenReference
                                              ? AppColors.primaryDark
                                              : AppColors.body,
                                          fontWeight: FontWeight.w600,
                                          decoration: c.canOpenReference
                                              ? TextDecoration.underline
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (c.canOpenReference)
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() => DocumentPrimaryButton(
                      label: task.isOpen
                          ? 'task_mark_done'.tr
                          : 'task_reopen'.tr,
                      icon: task.isOpen
                          ? Icons.check_circle_outline
                          : Icons.restart_alt,
                      busy: c.isUpdating.value,
                      onPressed: () => _handleToggle(context, c),
                    )),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    TaskDetailController c,
  ) async {
    if (c.isUpdating.value) return;
    final current = c.task.value;
    if (current == null) return;
    final closing = current.isOpen;

    if (closing) {
      final ok = await showAppConfirmDialog(
        context: context,
        title: 'confirm_close_task'.tr,
      );
      if (!ok) return;
    }
    final result = await c.toggleStatus();
    if (result.isAuthHandled) return;
    if (result.error == 'busy') return;
    if (result.isSuccess) {
      Get.snackbar(
        'success'.tr,
        closing ? 'task_closed_success'.tr : 'task_reopened_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'error'.tr,
        result.error ?? 'error_occurred'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
