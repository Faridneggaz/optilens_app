import '../entities/task.dart';

abstract class TaskRepository {
  Future<TaskListResponse> fetchTasks({
    required String token,
    String scope = 'mine',
    String status = 'Active',
    String? date,
    bool includeOverdue = true,
    String? allocatedTo,
    String? searchText,
    int limit = 20,
    int offset = 0,
  });
  Future<TaskDetailResponse> fetchTaskDetail({
    required String token,
    required String name,
  });
  Future<TaskOptions> getOptions({
    required String token,
    String kind = 'all',
    String? searchText,
    String? company,
  });
  Future<ErpTask> createTask({required String token, required TaskInput input});
  Future<ErpTask> updateTask({
    required String token,
    required String name,
    required String modified,
    TaskInput? input,
    String? status,
    double? progress,
  });
}
