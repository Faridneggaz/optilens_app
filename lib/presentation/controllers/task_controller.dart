import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/task.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/task_usecases.dart';
import '../../utils/error_feedback.dart';
import 'session_controller.dart';

enum TaskListFilter {
  active,
  today,
  open,
  working,
  review,
  completed,
  overdue,
  all,
}

class TaskController extends GetxController {
  TaskController({TaskUseCases? tasks, String Function()? tokenProvider})
    : _tasks = tasks ?? Get.find<TaskUseCases>(),
      _tokenProvider = tokenProvider;
  final TaskUseCases _tasks;
  final String Function()? _tokenProvider;
  final items = <ErpTask>[].obs;
  final summary = const TaskSummary().obs;
  final listDate = ''.obs;
  final listUser = ''.obs;
  final canCreate = false.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final scope = 'mine'.obs;
  final filter = TaskListFilter.active.obs;
  final allocatedToFilter = ''.obs;
  final searchController = TextEditingController();
  final allocatedToController = TextEditingController();
  final List<Worker> _workers = [];
  int _offset = 0;
  int _generation = 0;
  String get _token =>
      _tokenProvider?.call() ?? Get.find<SessionService>().authToken;
  String get currentUserEmail => listUser.value.isNotEmpty
      ? listUser.value
      : Get.find<SessionService>().userCode.trim();
  bool get showEmployeeFilter => scope.value == 'accessible';
  String get displayDate => listDate.value;

  AssignableUser? get currentAssignableUser {
    final email = currentUserEmail;
    if (email.isEmpty) return null;
    final name = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().userName.value
        : email;
    return AssignableUser(email: email, fullName: name);
  }

  @override
  void onInit() {
    super.onInit();
    _workers.add(
      debounce(
        searchQuery,
        (_) => onRefresh(),
        time: const Duration(milliseconds: 350),
      ),
    );
    _workers.add(ever(filter, (_) => onRefresh()));
    _workers.add(
      ever(scope, (value) {
        if (value == 'mine') {
          allocatedToFilter.value = '';
          allocatedToController.clear();
        }
        onRefresh();
      }),
    );
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    searchController.dispose();
    allocatedToController.dispose();
    super.onClose();
  }

  Future<void> onRefresh() async {
    final generation = ++_generation;
    _offset = 0;
    hasMore.value = false;
    items.clear();
    summary.value = const TaskSummary();
    errorMessage.value = '';
    isLoading.value = true;
    isLoadingMore.value = false;
    await _fetch(generation);
  }

  Future<void> softRefresh() => onRefresh();

  Future<void> onLoadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
    errorMessage.value = '';
    isLoadingMore.value = true;
    await _fetch(_generation, more: true);
  }

  Future<void> _fetch(int generation, {bool more = false}) async {
    try {
      final response = await _tasks.fetchTasks(
        token: _token,
        scope: scope.value,
        status: _status(filter.value),
        date: filter.value == TaskListFilter.today ? 'today' : null,
        allocatedTo: allocatedToFilter.value.isEmpty
            ? null
            : allocatedToFilter.value,
        searchText: searchQuery.value.trim(),
        offset: _offset,
      );
      if (generation != _generation || isClosed) return;
      summary.value = response.summary;
      listUser.value = response.user;
      listDate.value = response.date;
      canCreate.value = response.canCreate;
      if (more) {
        final known = items.map((t) => t.name).toSet();
        items.addAll(response.tasks.where((t) => !known.contains(t.name)));
      } else {
        items.assignAll(response.tasks);
      }
      _offset += response.tasks.length;
      hasMore.value = response.hasMore;
    } catch (error) {
      if (generation != _generation || isClosed) return;
      errorMessage.value = error is AccessDeniedException
          ? 'error_access_denied'.tr
          : ErrorFeedback.message(error, fallbackKey: 'failed_load_tasks');
      if (error is AccessDeniedException || error is InvalidSessionException) {
        canCreate.value = false;
      }
    } finally {
      if (generation == _generation && !isClosed) {
        isLoading.value = false;
        isLoadingMore.value = false;
      }
    }
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
      return (await _tasks.getOptions(
        token: _token,
        kind: 'users',
        searchText: query,
      )).users;
    } catch (error) {
      if (error is! AccessDeniedException &&
          error is! InvalidSessionException) {
        ErrorFeedback.snackbar(
          error,
          fallbackKey: 'failed_load_assignable_users',
        );
      }
      return const [];
    }
  }

  Future<TaskOptions> loadOptions({
    String kind = 'all',
    String? search,
    String? company,
  }) => _tasks.getOptions(
    token: _token,
    kind: kind,
    searchText: search,
    company: company,
  );

  Future<ErpTask> saveTask(TaskInput input, {ErpTask? task}) async {
    final saved = task == null
        ? await _tasks.createTask(token: _token, input: input)
        : await _tasks.updateTask(
            token: _token,
            name: task.name,
            modified: task.modified,
            input: input,
          );
    unawaited(onRefresh());
    return saved;
  }

  void openDetail(ErpTask task) =>
      Get.toNamed(AppRoutes.taskDetail, arguments: {'name': task.name});

  static String _status(TaskListFilter filter) => switch (filter) {
    TaskListFilter.active || TaskListFilter.today => 'Active',
    TaskListFilter.open => 'Open',
    TaskListFilter.working => 'Working',
    TaskListFilter.review => 'Pending Review',
    TaskListFilter.completed => 'Completed',
    TaskListFilter.overdue => 'Overdue',
    TaskListFilter.all => 'All',
  };

  String filterLabel(TaskListFilter value) => switch (value) {
    TaskListFilter.active => 'erp_task_active'.tr,
    TaskListFilter.today => 'tasks_filter_today'.tr,
    TaskListFilter.open => 'erp_task_open'.tr,
    TaskListFilter.working => 'erp_task_working'.tr,
    TaskListFilter.review => 'erp_task_review'.tr,
    TaskListFilter.completed => 'erp_task_completed'.tr,
    TaskListFilter.overdue => 'task_overdue'.tr,
    TaskListFilter.all => 'tasks_filter_all'.tr,
  };
}
