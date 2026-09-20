import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import 'task_controller.dart';

class TaskDetailController extends GetxController {
  TaskDetailController({TaskUseCases? tasks, String? name})
      : _tasks = tasks ?? Get.find<TaskUseCases>(),
        _name = name ?? '';

  final TaskUseCases _tasks;
  String _name;

  final task = Rxn<TodoTask>();
  final isLoading = true.obs;
  final isUpdating = false.obs;

  String get _token => Get.find<SessionService>().authToken;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _name = args['name']?.toString() ?? _name;
    } else if (args is String && args.isNotEmpty) {
      _name = args;
    }
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    if (_name.isEmpty) {
      isLoading.value = false;
      return;
    }
    isLoading.value = true;
    try {
      task.value = await _tasks.fetchTaskDetail(token: _token, name: _name);
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_task_detail');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActionResult> toggleStatus() async {
    final current = task.value;
    if (current == null) {
      return ActionResult.failure('error_occurred'.tr);
    }
    if (isUpdating.value) {
      return ActionResult.failure('busy');
    }
    final next = current.isOpen ? 'Closed' : 'Open';
    isUpdating.value = true;
    try {
      final result = await _tasks.updateTaskStatus(
        token: _token,
        name: current.name,
        status: next,
      );
      if (result.isSuccess) {
        current.status = next;
        task.refresh();
        // Refresh list in background — never await it while the button is busy.
        if (Get.isRegistered<TaskController>()) {
          Get.find<TaskController>().softRefresh();
        }
        // Re-fetch detail so status matches the server after reopen/close cycles.
        await _reloadDetailQuietly();
      }
      return result;
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> _reloadDetailQuietly() async {
    if (_name.isEmpty) return;
    try {
      final fresh = await _tasks.fetchTaskDetail(token: _token, name: _name);
      task.value = fresh;
    } catch (_) {
      // Keep optimistic local status if silent reload fails.
    }
  }

  void openReference() {
    final current = task.value;
    if (current == null || !current.hasReference) return;
    final type = current.referenceType.toLowerCase();
    final name = current.referenceName;
    if (type.contains('stock entry') || type.contains('stock_entry')) {
      Get.toNamed(AppRoutes.stockEntry, arguments: {'name': name});
      return;
    }
    if (type.contains('material request') ||
        type.contains('material_request')) {
      Get.toNamed(AppRoutes.materialRequestDetail, arguments: name);
    }
  }

  bool get canOpenReference {
    final current = task.value;
    if (current == null || !current.hasReference) return false;
    final type = current.referenceType.toLowerCase();
    return type.contains('stock entry') ||
        type.contains('stock_entry') ||
        type.contains('material request') ||
        type.contains('material_request');
  }
}
