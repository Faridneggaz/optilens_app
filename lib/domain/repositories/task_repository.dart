import '../entities/task.dart';
import '../results/action_result.dart';

abstract class TaskRepository {
  Future<TaskListResponse> fetchMyTasks({
    required String token,
    String status = 'Open',
    String? date,
    bool includeOverdue = true,
    String? searchText,
    int limit = 20,
    int offset = 0,
  });

  Future<TodoTask> fetchTaskDetail({
    required String token,
    required String name,
  });

  Future<ActionResult> updateTaskStatus({
    required String token,
    required String name,
    required String status,
  });
}
