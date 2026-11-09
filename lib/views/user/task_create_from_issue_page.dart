import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../widgets/task/task_form_sheet.dart';

class TaskCreateFromIssuePage extends StatelessWidget {
  const TaskCreateFromIssuePage({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments is Map
        ? Map<String, dynamic>.from(Get.arguments as Map)
        : <String, dynamic>{};
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: TaskFormSheet(
          controller: Get.find<TaskController>(),
          initialSubject: '${args['subject'] ?? ''}',
          initialDescription: '${args['description'] ?? ''}',
          issue: '${args['issue'] ?? ''}',
        ),
      ),
    );
  }
}
