import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';
import 'session_controller.dart';

enum TaskListFilter { today, open, closed, all }

class TaskController extends GetxController {
  TaskController({TaskUseCases? tasks})
      : _tasks = tasks ?? Get.find<TaskUseCases>();

  final TaskUseCases _tasks;

  final items = <TodoTask>[].obs;
  final summary = const TaskSummary(
    totalItems: 0,
    openCount: 0,
    closedCount: 0,
    overdueCount: 0,
  ).obs;
  final listDate = ''.obs;
  final listUser = ''.obs;
  final canCreate = false.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchQuery = ''.obs;
  final filter = TaskListFilter.today.obs;
  final allocatedToFilter = ''.obs;
  final knownAssignees = <String>[].obs;
  final updatingNames = <String>{}.obs;

  final searchController = TextEditingController();
  final allocatedToController = TextEditingController();
  Worker? _debounce;
  int _offset = 0;
  static const int _limit = 20;

  String get _token => Get.find<SessionService>().authToken;

  String get currentUserEmail {
    if (listUser.value.trim().isNotEmpty) return listUser.value.trim();
    return Get.find<SessionService>().userCode.trim();
  }

  bool get showEmployeeFilter {
    if (canCreate.value) return true;
    return knownAssignees.length > 1;
  }

  String get displayDate {
    if (listDate.value.isNotEmpty) return listDate.value;
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool isAssignedToCurrentUser(TodoTask task) {
    final me = currentUserEmail.toLowerCase();
    if (me.isEmpty) return true;
    final allocated = task.allocatedTo.trim().toLowerCase();
    if (allocated.isEmpty) return true;
    return allocated == me;
  }

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce(
      searchQuery,
      (_) => onRefresh(),
      time: const Duration(milliseconds: 400),
    );
    ever(filter, (_) => onRefresh());
    onRefresh();
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    allocatedToController.dispose();
    super.onClose();
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    hasMore.value = true;
    _offset = 0;
    items.clear();
    await fetchTasks();
  }

  /// List refresh that does not hold the status-update lock.
  Future<void> softRefresh() async {
    hasMore.value = true;
    _offset = 0;
    await fetchTasks();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchTasks(isLoadMore: true);
    }
  }

  Future<void> fetchTasks({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else if (items.isEmpty) {
        isLoading.value = true;
      }

      final params = _queryForFilter(filter.value);
      final response = await _tasks.fetchMyTasks(
        token: _token,
        status: params.status,
        date: params.date,
        includeOverdue: params.includeOverdue,
        allocatedTo: allocatedToFilter.value.trim().isEmpty
            ? null
            : allocatedToFilter.value.trim(),
        searchText: searchQuery.value.trim().isEmpty
            ? null
            : searchQuery.value.trim(),
        limit: _limit,
        offset: _offset,
      );

      summary.value = response.summary;
      canCreate.value = response.canCreate;
      if (response.user.isNotEmpty) {
        listUser.value = response.user;
      }
      if (response.date.isNotEmpty) {
        listDate.value = response.date;
      }

      if (isLoadMore) {
        items.addAll(response.tasks);
      } else {
        items.value = response.tasks;
      }

      _mergeKnownAssignees(response.tasks);

      hasMore.value = response.hasMore;
      if (response.tasks.isNotEmpty) {
        _offset += response.tasks.length;
      }
    } catch (e) {
      if (e is InvalidSessionException || e is AccessDeniedException) {
        return;
      }
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_tasks');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  void _mergeKnownAssignees(List<TodoTask> tasks) {
    final next = <String>{...knownAssignees};
    for (final t in tasks) {
      final email = t.allocatedTo.trim();
      if (email.isNotEmpty) next.add(email);
    }
    final sorted = next.toList()..sort();
    knownAssignees.value = sorted;
  }

  void setAllocatedToFilter(String? email) {
    final value = (email ?? '').trim();
    if (allocatedToFilter.value == value) return;
    allocatedToFilter.value = value;
    allocatedToController.text = value;
    onRefresh();
  }

  void clearAllocatedToFilter() => setAllocatedToFilter('');

  Future<List<AssignableUser>> searchAssignableUsers(String query) async {
    try {
      return await _tasks.getAssignableUsers(
        token: _token,
        searchText: query.trim(),
      );
    } catch (e) {
      if (e is InvalidSessionException || e is AccessDeniedException) {
        return const [];
      }
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_assignable_users');
      return const [];
    }
  }

  AssignableUser? get currentAssignableUser {
    final email = currentUserEmail;
    if (email.isEmpty) return null;
    String fullName = email;
    if (Get.isRegistered<SessionController>()) {
      final name = Get.find<SessionController>().userName.value.trim();
      if (name.isNotEmpty) fullName = name;
    }
    return AssignableUser(email: email, fullName: fullName);
  }

  Future<ActionResult> createTodo({
    required String description,
    required String allocatedTo,
    required String date,
    required String priority,
  }) async {
    final result = await _tasks.createTodo(
      token: _token,
      description: description,
      allocatedTo: allocatedTo,
      date: date,
      priority: priority,
    );
    if (result.isSuccess) {
      await onRefresh();
    }
    return result;
  }

  Future<ActionResult> markDone(TodoTask task) =>
      _setStatus(task, 'Closed');

  Future<ActionResult> reopen(TodoTask task) =>
      _setStatus(task, 'Open');

  Future<ActionResult> _setStatus(TodoTask task, String status) async {
    if (updatingNames.contains(task.name)) {
      return ActionResult.failure('busy');
    }
    updatingNames.add(task.name);
    updatingNames.refresh();
    try {
      final result = await _tasks.updateTaskStatus(
        token: _token,
        name: task.name,
        status: status,
      );
      if (result.isSuccess) {
        task.status = status;
        // Drop from current filtered list when it no longer matches.
        if (status == 'Closed' &&
            filter.value != TaskListFilter.closed &&
            filter.value != TaskListFilter.all) {
          items.removeWhere((t) => t.name == task.name);
        } else if (status == 'Open' &&
            filter.value == TaskListFilter.closed) {
          items.removeWhere((t) => t.name == task.name);
        } else {
          items.refresh();
        }
      }
      return result;
    } finally {
      updatingNames.remove(task.name);
      updatingNames.refresh();
      // Refresh counts after unlock so a slow list call cannot freeze the CTA.
      softRefresh();
    }
  }

  void openDetail(TodoTask task) {
    Get.toNamed(AppRoutes.taskDetail, arguments: {'name': task.name});
  }

  static ({String status, String? date, bool includeOverdue}) _queryForFilter(
    TaskListFilter filter,
  ) {
    switch (filter) {
      case TaskListFilter.today:
        return (status: 'Open', date: 'today', includeOverdue: true);
      case TaskListFilter.open:
        return (status: 'Open', date: null, includeOverdue: false);
      case TaskListFilter.closed:
        return (status: 'Closed', date: null, includeOverdue: false);
      case TaskListFilter.all:
        return (status: 'All', date: null, includeOverdue: true);
    }
  }

  String filterLabel(TaskListFilter value) {
    switch (value) {
      case TaskListFilter.today:
        return 'tasks_filter_today'.tr;
      case TaskListFilter.open:
        return 'tasks_filter_open'.tr;
      case TaskListFilter.closed:
        return 'tasks_filter_closed'.tr;
      case TaskListFilter.all:
        return 'tasks_filter_all'.tr;
    }
  }
}
