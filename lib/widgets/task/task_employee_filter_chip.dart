import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import 'pick_assignable_user_sheet.dart';

/// Compact employee filter chip — opens a dedicated picker sheet (no 2nd search bar).
class TaskEmployeeFilterChip extends StatelessWidget {
  const TaskEmployeeFilterChip({super.key, required this.controller});

  final TaskController controller;

  Future<void> _openPicker(BuildContext context) async {
    final selectedEmail = controller.allocatedToFilter.value;
    final picked = await showAssignableUserPicker(
      context: context,
      controller: controller,
      selected: selectedEmail.isEmpty
          ? null
          : AssignableUser(email: selectedEmail, fullName: selectedEmail),
      allowClear: true,
    );
    if (picked == null) return;
    if (picked.email.trim().isEmpty) {
      controller.clearAllocatedToFilter();
    } else {
      controller.setAllocatedToFilter(picked.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.showEmployeeFilter) return const SizedBox.shrink();

      final email = controller.allocatedToFilter.value;
      final hasFilter = email.isNotEmpty;
      final label = hasFilter ? email : 'tasks_filter_employee'.tr;

      return Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: InputChip(
          avatar: Icon(
            Icons.person_outline,
            size: 18,
            color: hasFilter ? AppColors.primaryDark : AppColors.muted,
          ),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasFilter ? AppColors.primaryDark : AppColors.body,
                fontWeight: hasFilter ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          selected: hasFilter,
          showCheckmark: false,
          onPressed: () => _openPicker(context),
          onDeleted: hasFilter ? controller.clearAllocatedToFilter : null,
          deleteIconColor: AppColors.primaryDark,
          selectedColor: AppColors.primary.withValues(alpha: 0.18),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: hasFilter ? AppColors.primary : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      );
    });
  }
}
