import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';

String taskStatusLabel(String status) => switch (status) {
  'Open' => 'erp_task_open'.tr,
  'Working' => 'erp_task_working'.tr,
  'Pending Review' => 'erp_task_review'.tr,
  'Completed' => 'erp_task_completed'.tr,
  'Cancelled' => 'erp_task_cancelled'.tr,
  'Overdue' => 'task_overdue'.tr,
  'Template' => 'erp_task_template'.tr,
  _ => status,
};
String taskPriorityLabel(String priority) => switch (priority) {
  'Low' => 'erp_task_low'.tr,
  'Medium' => 'erp_task_medium'.tr,
  'High' => 'erp_task_high'.tr,
  'Urgent' => 'erp_task_urgent'.tr,
  _ => priority,
};

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Completed' => Colors.green,
      'Cancelled' || 'Overdue' => AppColors.danger,
      'Working' => AppColors.primary,
      'Pending Review' => Colors.orange.shade800,
      _ => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        taskStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TaskPriorityChip extends StatelessWidget {
  const TaskPriorityChip({super.key, required this.priority});
  final String priority;
  @override
  Widget build(BuildContext context) => Text(
    taskPriorityLabel(priority),
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: priority == 'High' || priority == 'Urgent'
          ? AppColors.danger
          : AppColors.muted,
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.controller});
  final ErpTask task;
  final TaskController controller;
  @override
  Widget build(BuildContext context) {
    final people = task.isFinished ? task.previousAssignees : task.assignees;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.dividerMint),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.openDetail(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.subject,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TaskStatusChip(status: task.status),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  TaskPriorityChip(priority: task.priority),
                  if (task.endDate.isNotEmpty)
                    Text(
                      task.endDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: task.isOverdue
                            ? AppColors.danger
                            : AppColors.muted,
                      ),
                    ),
                  if (task.isOverdue)
                    Text(
                      'task_overdue'.tr,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              if (people.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  people.map((p) => p.displayName).join(' · '),
                  style: const TextStyle(color: AppColors.body, fontSize: 12),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (task.progress / 100).clamp(0, 1),
                      backgroundColor: AppColors.scaffold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${task.progress.round()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
