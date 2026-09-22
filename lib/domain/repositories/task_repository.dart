import '../entities/task.dart';
import '../results/action_result.dart';

abstract class TaskRepository {
  Future<TaskListResponse> fetchMyTasks({
    required String token,
    String status = 'Open',
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

  Future<List<AssignableUser>> getAssignableUsers({
    required String token,
    String? searchText,
  });

  Future<ActionResult> createTodo({
    required String token,
    required String description,
    required String allocatedTo,
    required String date,
    required String priority,
  });

  Future<ActionResult> updateTaskStatus({
    required String token,
    required String name,
    required String status,
  });
}
