import '../entities/task.dart';
import '../repositories/task_repository.dart';

class TaskUseCases {
  TaskUseCases(this._repo);
  final TaskRepository _repo;

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
  }) => _repo.fetchTasks(
    token: token,
    scope: scope,
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
  }) => _repo.fetchTaskDetail(token: token, name: name);
  Future<TaskOptions> getOptions({
    required String token,
    String kind = 'all',
    String? searchText,
    String? company,
  }) => _repo.getOptions(
    token: token,
    kind: kind,
    searchText: searchText,
    company: company,
  );
  Future<ErpTask> createTask({
    required String token,
    required TaskInput input,
  }) => _repo.createTask(token: token, input: input);
  Future<ErpTask> updateTask({
    required String token,
    required String name,
    required String modified,
    TaskInput? input,
    String? status,
    double? progress,
  }) => _repo.updateTask(
    token: token,
    name: name,
    modified: modified,
    input: input,
    status: status,
    progress: progress,
  );
}
