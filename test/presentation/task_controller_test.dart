import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:optilens/domain/entities/task.dart';
import 'package:optilens/domain/repositories/task_repository.dart';
import 'package:optilens/domain/usecases/task_usecases.dart';
import 'package:optilens/presentation/controllers/task_controller.dart';
import 'package:optilens/presentation/controllers/task_detail_controller.dart';

class FakeTasks implements TaskRepository {
  final requests = <Future<TaskListResponse>>[];
  int calls = 0;
  int updates = 0;
  String? updatedStatus;
  String? updatedVersion;
  final queries = <String>[];
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
  }) {
    queries.add('$scope/$status/$offset');
    return requests[calls++];
  }

  @override
  Future<ErpTask> updateTask({
    required String token,
    required String name,
    required String modified,
    TaskInput? input,
    String? status,
    double? progress,
  }) async {
    updates++;
    updatedStatus = status;
    updatedVersion = modified;
    return ErpTask(
      name: name,
      subject: 'Done',
      status: status ?? 'Open',
      progress: 100,
    );
  }

  @override
  Future<TaskOptions> getOptions({
    required String token,
    String kind = 'all',
    String? searchText,
    String? company,
  }) async => const TaskOptions(
    canCreate: true,
    priorities: ['Low', 'Medium', 'High', 'Urgent'],
    users: [
      AssignableUser(email: 'a@example.com', fullName: 'Alice'),
      AssignableUser(email: 'b@example.com', fullName: 'Bob'),
    ],
  );
  @override
  Future<TaskDetailResponse> fetchTaskDetail({
    required String token,
    required String name,
  }) => throw UnimplementedError();
  @override
  Future<ErpTask> createTask({
    required String token,
    required TaskInput input,
  }) => throw UnimplementedError();
}

TaskListResponse listing(String name, {bool more = false}) => TaskListResponse(
  user: 'a@example.com',
  date: '2026-10-21',
  summary: const TaskSummary(totalItems: 2),
  tasks: [ErpTask(name: name, subject: name)],
  hasMore: more,
);

void main() {
  setUp(() {
    Get.testMode = true;
  });
  tearDown(Get.reset);

  test(
    'a late response cannot overwrite the new scope or pagination',
    () async {
      final old = Completer<TaskListResponse>();
      final latest = Completer<TaskListResponse>();
      final repo = FakeTasks()..requests.addAll([old.future, latest.future]);
      final c = TaskController(
        tasks: TaskUseCases(repo),
        tokenProvider: () => 'sid',
      );
      final first = c.onRefresh();
      c.scope.value = 'accessible';
      final second = c.onRefresh();
      latest.complete(listing('TASK-NEW'));
      await second;
      old.complete(listing('TASK-OLD'));
      await first;
      expect(c.items.single.name, 'TASK-NEW');
      expect(repo.queries, ['mine/Active/0', 'accessible/Active/0']);
      expect(c.isLoading.value, isFalse);
      c.onClose();
    },
  );

  test('completed filter and load-more are server driven', () async {
    final repo = FakeTasks()
      ..requests.addAll([
        Future.value(listing('TASK-1', more: true)),
        Future.value(listing('TASK-2')),
      ]);
    final c = TaskController(
      tasks: TaskUseCases(repo),
      tokenProvider: () => 'sid',
    );
    c.filter.value = TaskListFilter.completed;
    await c.onRefresh();
    await c.onLoadMore();
    expect(c.items.map((t) => t.name), ['TASK-1', 'TASK-2']);
    expect(repo.queries, ['mine/Completed/0', 'mine/Completed/1']);
    expect(c.hasMore.value, isFalse);
    c.onClose();
  });

  test('read-only Task cannot send a status update', () async {
    final repo = FakeTasks();
    final c = TaskDetailController(
      tasks: TaskUseCases(repo),
      tokenProvider: () => 'sid',
    );
    c.task.value = const ErpTask(name: 'TASK-1', subject: 'Read only');
    final result = await c.changeStatus('Completed');
    expect(result.isSuccess, isFalse);
    expect(repo.updates, 0);
  });

  test(
    'status update keeps server Task and uses its modification version',
    () async {
      final repo = FakeTasks();
      final c = TaskDetailController(
        tasks: TaskUseCases(repo),
        tokenProvider: () => 'sid',
      );
      c.task.value = const ErpTask(
        name: 'TASK-1',
        subject: 'Work',
        modified: 'v1',
        canWrite: true,
        allowedStatuses: ['Working', 'Completed'],
      );
      final result = await c.changeStatus('Completed');
      expect(result.isSuccess, isTrue);
      expect(repo.updatedStatus, 'Completed');
      expect(repo.updatedVersion, 'v1');
      expect(c.task.value!.progress, 100);
      expect(c.task.value!.canWrite, isFalse);
      expect(c.isUpdating.value, isFalse);
    },
  );
}
