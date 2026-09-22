import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import '../stock/document_ui.dart';

class TaskPriorityChip extends StatelessWidget {
  const TaskPriorityChip({super.key, required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final p = priority.toLowerCase();
    late final Color bg;
    late final Color fg;
    if (p == 'high') {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFB91C1C);
    } else if (p == 'medium') {
      bg = const Color(0xFFFFF7ED);
      fg = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFF3F4F6);
      fg = const Color(0xFF4B5563);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.controller,
  });

  final TodoTask task;
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final busy = controller.updatingNames.contains(task.name);

    return Dismissible(
      key: ValueKey('task_${task.name}'),
      direction: task.isOpen
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        if (!task.isOpen) return false;
        final ok = await showAppConfirmDialog(
          context: context,
          title: 'confirm_close_task'.tr,
        );
        if (!ok) return false;
        final result = await controller.markDone(task);
        if (result.isAuthHandled) return false;
        if (result.isSuccess) {
          Get.snackbar(
            'success'.tr,
            'task_closed_success'.tr,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        } else if (result.error != null && result.error != 'busy') {
          Get.snackbar(
            'error'.tr,
            result.error ?? 'error_occurred'.tr,
            backgroundColor: Colors.red.shade100,
            colorText: Colors.red.shade900,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
        // Keep false: list ownership stays with TaskController (avoids Dismissible errors).
        return false;
      },
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'task_mark_done'.tr,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_outline, color: Colors.white),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => controller.openDetail(task),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          task.description.isNotEmpty
                              ? task.description
                              : task.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TaskPriorityChip(priority: task.priority),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        task.date,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      if (task.isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'task_overdue'.tr,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      if (task.isOpen)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final ok = await showAppConfirmDialog(
                                    context: context,
                                    title: 'confirm_close_task'.tr,
                                  );
                                  if (!ok) return;
                                  final result =
                                      await controller.markDone(task);
                                  if (result.isAuthHandled) return;
                                  if (result.isSuccess) {
                                    Get.snackbar(
                                      'success'.tr,
                                      'task_closed_success'.tr,
                                      backgroundColor: Colors.green,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  } else if (result.error != null &&
                                      result.error != 'busy') {
                                    Get.snackbar(
                                      'error'.tr,
                                      result.error ?? 'error_occurred'.tr,
                                      backgroundColor: Colors.red.shade100,
                                      colorText: Colors.red.shade900,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  }
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Text(
                                  'task_mark_done'.tr,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  if (!controller.isAssignedToCurrentUser(task) &&
                      task.allocatedTo.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline,
                              size: 14, color: AppColors.primaryDark),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${'task_assigned_to_chip'.tr}${task.allocatedTo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (task.hasReference) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'task_ref_prefix'.tr}${task.referenceType} / ${task.referenceName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
