import 'dart:typed_data';

import 'dart:convert';

import '../../core/network/api_client.dart';
import '../../domain/entities/attachment_photo.dart';
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
  Future<Uint8List> fetchPhoto({
    required String token,
    required String taskName,
    required String fileId,
    required bool thumbnail,
  }) => _client.postMobileImage(
    'get_task_photo',
    body: {
      'token': token,
      'name': taskName,
      'file_id': fileId,
      'thumbnail': thumbnail,
    },
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
    if (input.issue.isNotEmpty) 'issue': input.issue,
    if (input.type.isNotEmpty) 'type': input.type,
    if (input.updateAssignments) 'assignees': input.assignees,
  };

  Future<ErpTask> _saveTask(
    String method,
    Map<String, dynamic> body, {
    SelectedPhoto? photo,
  }) async {
    final response = photo == null
        ? await _client.postMobile(method, attachToken: false, body: body)
        : await _client.postMobileFile(
            method,
            fields: body.map(
              (key, value) =>
                  MapEntry(key, value is String ? value : jsonEncode(value)),
            ),
            fieldName: 'photo',
            filename: photo.name,
            bytes: photo.bytes,
          );
    return TaskDetailResponseMapper.fromJson(_message(response)).task;
  }

  @override
  Future<ErpTask> createTask({
    required String token,
    required TaskInput input,
  }) => _saveTask('create_task', {
    'token': token,
    ..._input(input),
  }, photo: input.photo);

  @override
  Future<ErpTask> updateTask({
    required String token,
    required String name,
    required String modified,
    TaskInput? input,
    String? status,
    double? progress,
  }) => _saveTask('update_task', {
    'token': token,
    'name': name,
    'modified': modified,
    if (input != null) ..._input(input),
    if (status != null) 'status': status,
    if (progress != null) 'progress': progress,
  }, photo: input?.photo);
}
