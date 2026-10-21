import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/task_controller.dart';
import 'pick_assignable_user_sheet.dart';

/// Employee selection opens in its own searchable sheet, keeping the list clear.
class TaskEmployeeFilterBar extends StatefulWidget {
  const TaskEmployeeFilterBar({super.key, required this.controller});
  final TaskController controller;
  @override
  State<TaskEmployeeFilterBar> createState() => _TaskEmployeeFilterBarState();
}

class _TaskEmployeeFilterBarState extends State<TaskEmployeeFilterBar> {
  AssignableUser? _selected;
  @override
  Widget build(BuildContext context) => Obx(() {
    final c = widget.controller;
    if (!c.showEmployeeFilter) return const SizedBox.shrink();
    final email = c.allocatedToFilter.value;
    final selected = email.isEmpty
        ? null
        : (_selected?.email == email
              ? _selected
              : AssignableUser(email: email, fullName: email));
    return Flexible(
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          backgroundColor: selected == null ? Colors.white : AppColors.card,
          side: BorderSide(
            color: selected == null ? AppColors.dividerMint : AppColors.primary,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.person_outline, size: 18),
        label: Text(
          selected?.displayName ?? 'tasks_filter_employee'.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        onPressed: () async {
          final user = await showAssignableUserPicker(
            context: context,
            controller: c,
            selected: selected,
            allowClear: true,
          );
          if (!mounted || user == null) return;
          setState(() => _selected = user.email.isEmpty ? null : user);
          c.setAllocatedToFilter(user.email);
        },
      ),
    );
  });
}
