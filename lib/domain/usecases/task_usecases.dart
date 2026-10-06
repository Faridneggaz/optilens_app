import '../entities/task.dart';
import '../repositories/task_repository.dart';
import '../results/action_result.dart';

class TaskUseCases {
  TaskUseCases(this._repo);
  final TaskRepository _repo;

  Future<TaskListResponse> fetchMyTasks({
    required String token,
    String status = 'Open',
    String? date,
    bool includeOverdue = true,
    String? allocatedTo,
    String? searchText,
    int limit = 20,
    int offset = 0,
  }) =>
      _repo.fetchMyTasks(
        token: token,
        status: status,
        date: date,
        includeOverdue: includeOverdue,
        allocatedTo: allocatedTo,
        searchText: searchText,
        limit: limit,
        offset: offset,
      );

  Future<TaskDetailResponse> fetchTaskDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchTaskDetail(token: token, name: name);

  Future<List<AssignableUser>> getAssignableUsers({
    required String token,
    String? searchText,
  }) =>
      _repo.getAssignableUsers(token: token, searchText: searchText);

  Future<ActionResult> createTodo({
    required String token,
    required String description,
    required String allocatedTo,
    required String date,
    required String priority,
  }) =>
      _repo.createTodo(
        token: token,
        description: description,
        allocatedTo: allocatedTo,
        date: date,
        priority: priority,
      );

  Future<ActionResult> updateTaskStatus({
    required String token,
    required String name,
    required String status,
  }) =>
      _repo.updateTaskStatus(token: token, name: name, status: status);
}
