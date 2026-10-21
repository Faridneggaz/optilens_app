import 'dart:async';
import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../utils/error_feedback.dart';
import 'task_controller.dart';

class TaskDetailController extends GetxController {
  TaskDetailController({
    TaskUseCases? tasks,
    String? name,
    String Function()? tokenProvider,
  }) : _tasks = tasks ?? Get.find<TaskUseCases>(),
       _name = name ?? '',
       _tokenProvider = tokenProvider;
  final TaskUseCases _tasks;
  final String Function()? _tokenProvider;
  String _name;
  final task = Rxn<ErpTask>();
  final isLoading = true.obs;
  final isUpdating = false.obs;
  final errorMessage = ''.obs;
  String get _token =>
      _tokenProvider?.call() ?? Get.find<SessionService>().authToken;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) _name = args['name']?.toString() ?? _name;
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      task.value = (await _tasks.fetchTaskDetail(
        token: _token,
        name: _name,
      )).task;
    } catch (error) {
      task.value = null;
      errorMessage.value = ErrorFeedback.message(
        error,
        fallbackKey: 'failed_load_task_detail',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActionResult> changeStatus(String status) async {
    final current = task.value;
    if (current == null ||
        !current.canWrite ||
        !current.allowedStatuses.contains(status)) {
      return ActionResult.failure('error_access_denied'.tr);
    }
    if (isUpdating.value) return ActionResult.failure('busy');
    isUpdating.value = true;
    try {
      task.value = await _tasks.updateTask(
        token: _token,
        name: current.name,
        modified: current.modified,
        status: status,
      );
      if (Get.isRegistered<TaskController>()) {
        unawaited(Get.find<TaskController>().onRefresh());
      }
      return ActionResult.ok(documentName: current.name);
    } catch (error) {
      if (error is InvalidSessionException || error is AccessDeniedException) {
        return ActionResult.authHandled();
      }
      return ActionResult.failure(
        ErrorFeedback.message(error, fallbackKey: 'error_occurred'),
      );
    } finally {
      isUpdating.value = false;
    }
  }
}
