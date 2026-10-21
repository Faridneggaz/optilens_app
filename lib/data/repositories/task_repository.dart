import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/task_repository.dart';
import '../mappers/task_mappers.dart';

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this._client);
  final ApiClient _client;

  Map<String, dynamic> _message(Map<String, dynamic> decoded) {
    final value = _client.unwrap(decoded);
    if (value is! Map) throw const RepositoryException('Invalid Task response');
    final map = Map<String, dynamic>.from(value);
    final error = map['error']?.toString() ?? '';
    if (error.isNotEmpty) throw RepositoryException(error);
    return map;
  }

  @override
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
  }) async {
    final decoded = await _client.getMobile(
      'get_tasks',
      attachToken: false,
      query: {
        'token': token,
        'scope': scope,
        'status': status,
        'include_overdue': includeOverdue ? '1' : '0',
        'limit': '$limit',
        'offset': '$offset',
        if (date != null && date.isNotEmpty) 'date': date,
        if (allocatedTo != null && allocatedTo.isNotEmpty)
          'allocated_to': allocatedTo,
        if (searchText != null && searchText.isNotEmpty)
          'search_text': searchText,
      },
    );
    return TaskListResponseMapper.fromJson(_message(decoded));
  }

  @override
  Future<TaskDetailResponse> fetchTaskDetail({
    required String token,
    required String name,
  }) async => TaskDetailResponseMapper.fromJson(
    _message(
      await _client.getMobile(
        'get_task',
        attachToken: false,
        query: {'token': token, 'name': name},
      ),
    ),
  );

  @override
  Future<TaskOptions> getOptions({
    required String token,
    String kind = 'all',
    String? searchText,
    String? company,
  }) async => TaskOptionsMapper.fromJson(
    _message(
      await _client.getMobile(
        'get_task_options',
        attachToken: false,
        query: {
          'token': token,
          'kind': kind,
          if (searchText != null) 'search_text': searchText,
          if (company != null && company.isNotEmpty) 'company': company,
        },
      ),
    ),
  );

  Map<String, dynamic> _input(TaskInput input) => {
    'subject': input.subject.trim(),
    if (input.description != null)
      'description': const HtmlEscape()
          .convert(input.description!)
          .replaceAll('\n', '<br>'),
    'company': input.company,
    'project': input.project,
    'exp_start_date': input.startDate,
    'exp_end_date': input.endDate,
    'priority': input.priority,
    'progress': input.progress,
    if (input.updateAssignments) 'assignees': input.assignees,
  };

  @override
  Future<ErpTask> createTask({
    required String token,
    required TaskInput input,
  }) async => TaskDetailResponseMapper.fromJson(
    _message(
      await _client.postMobile(
        'create_task',
        attachToken: false,
        body: {'token': token, ..._input(input)},
      ),
    ),
  ).task;

  @override
  Future<ErpTask> updateTask({
    required String token,
    required String name,
    required String modified,
    TaskInput? input,
    String? status,
    double? progress,
  }) async => TaskDetailResponseMapper.fromJson(
    _message(
      await _client.postMobile(
        'update_task',
        attachToken: false,
        body: {
          'token': token,
          'name': name,
          'modified': modified,
          if (input != null) ..._input(input),
          if (status != null) 'status': status,
          if (progress != null) 'progress': progress,
        },
      ),
    ),
  ).task;
}
