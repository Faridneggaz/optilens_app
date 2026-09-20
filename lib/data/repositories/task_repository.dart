import '../../core/network/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/results/action_result.dart';
import '../mappers/json_mappers.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._client);

  final ApiClient _client;

  @override
  Future<TaskListResponse> fetchMyTasks({
    required String token,
    String status = 'Open',
    String? date,
    bool includeOverdue = true,
    String? searchText,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, String>{
      'token': token,
      'status': status,
      'include_overdue': includeOverdue ? '1' : '0',
      'limit': '$limit',
      'offset': '$offset',
    };
    if (date != null && date.isNotEmpty) {
      query['date'] = date;
    }
    if (searchText != null && searchText.trim().isNotEmpty) {
      query['search_text'] = searchText.trim();
    }

    final decoded = await _client.getMobile(
      'get_my_tasks',
      query: query,
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    if (msg is Map) {
      final map = Map<String, dynamic>.from(msg);
      final err = map['error']?.toString();
      if (err != null && err.isNotEmpty && map['success'] != true) {
        throw RepositoryException(err);
      }
      return TaskListResponseMapper.fromJson(map);
    }
    if (decoded['message'] is Map || decoded.containsKey('tasks')) {
      return TaskListResponseMapper.fromJson(decoded);
    }
    throw const RepositoryException('Invalid tasks response');
  }

  @override
  Future<TodoTask> fetchTaskDetail({
    required String token,
    required String name,
  }) async {
    final decoded = await _client.getMobile(
      'get_task_detail',
      query: {
        'token': token,
        'name': name,
      },
      attachToken: false,
    );
    final msg = _client.unwrap(decoded);
    if (msg is Map) {
      final map = Map<String, dynamic>.from(msg);
      final err = map['error']?.toString();
      if (err != null && err.isNotEmpty && map['success'] != true) {
        throw RepositoryException(err);
      }
      final taskRaw = map['task'];
      if (taskRaw is Map) {
        return TodoTaskMapper.fromJson(Map<String, dynamic>.from(taskRaw));
      }
    }
    if (decoded['task'] is Map) {
      return TodoTaskMapper.fromJson(
        Map<String, dynamic>.from(decoded['task'] as Map),
      );
    }
    throw const RepositoryException('Invalid task detail response');
  }

  @override
  Future<ActionResult> updateTaskStatus({
    required String token,
    required String name,
    required String status,
  }) async {
    try {
      final decoded = await _client.postMobile(
        'update_my_task_status',
        body: {
          'token': token,
          'name': name,
          'status': status,
        },
        attachToken: false,
      );
      final msg = _client.unwrap(decoded);
      if (msg is Map) {
        final map = Map<String, dynamic>.from(msg);
        final parsed = ActionResult.fromApiMap(map);
        if (parsed.isSuccess) return parsed;
        // Some Frappe handlers return the updated task without a "Success" string.
        final updated = map['task'] ?? map['status'] ?? map['name'];
        if (map['success'] == true ||
            updated != null ||
            map['message']?.toString().toLowerCase().contains('success') ==
                true) {
          return ActionResult.ok(
            message: 'Success',
            detail: map['detail']?.toString(),
            documentName: name,
          );
        }
        return parsed;
      }
      if (msg is String) {
        final lower = msg.toLowerCase();
        if (lower.contains('success') ||
            lower.contains('closed') ||
            lower.contains('open') ||
            lower.contains('updated')) {
          return ActionResult.ok(message: msg, documentName: name);
        }
      }
      return ActionResult.fromApiMap(decoded);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }
}
