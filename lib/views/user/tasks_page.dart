import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/task.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/stock/document_ui.dart';
import '../../widgets/task/task_card.dart';
import '../../widgets/task/task_employee_filter_bar.dart';
import '../../widgets/task/task_form_sheet.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});
  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Get.find<TaskController>().onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TaskController>();
    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        floatingActionButton: Obx(
          () => c.canCreate.value
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  onPressed: () =>
                      showTaskForm(context: context, controller: c),
                  icon: const Icon(Icons.add),
                  label: Text('task_new'.tr),
                )
              : const SizedBox.shrink(),
        ),
        body: Column(
          children: [
            AppHeader(
              title: 'nav_my_tasks'.tr,
              customer: null,
              customerCode: '',
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: c.onRefresh,
                child: Obx(
                  () => ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 18, bottom: 100),
                    children: [
                      TaskListControls(controller: c),
                      if (c.isLoading.value)
                        const Padding(
                          padding: EdgeInsets.all(56),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (!c.isLoading.value &&
                          c.items.isEmpty &&
                          c.errorMessage.value.isNotEmpty)
                        _TaskMessage(
                          error: true,
                          reason: c.errorMessage.value,
                          onRetry: c.onRefresh,
                        ),
                      if (!c.isLoading.value &&
                          (c.errorMessage.value.isEmpty ||
                              c.items.isNotEmpty)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${'erp_task_results'.tr} (${c.summary.value.totalItems})',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              if (c.summary.value.overdueCount > 0)
                                Text(
                                  '${c.summary.value.overdueCount} ${'task_overdue'.tr.toLowerCase()}',
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (c.items.isEmpty) const _TaskMessage(),
                        ...c.items.map(
                          (task) => TaskCard(task: task, controller: c),
                        ),
                      ],
                      if (c.items.isNotEmpty && c.errorMessage.value.isNotEmpty)
                        _TaskMessage(
                          error: true,
                          reason: c.errorMessage.value,
                          onRetry: () => c.onLoadMore(),
                        ),
                      DocumentLoadMoreFooter(
                        hasMore: c.hasMore.value,
                        isLoadingMore: c.isLoadingMore.value,
                        hasItems: c.items.isNotEmpty,
                        isSearching: c.searchQuery.value.isNotEmpty,
                        onLoadMore: c.onLoadMore,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact controls; all status choices remain available in the menu.
class TaskListControls extends StatelessWidget {
  const TaskListControls({super.key, required this.controller});
  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Obx(
            () => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.dividerMint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (final scope in ['mine', 'accessible'])
                    Expanded(
                      child: Material(
                        color: c.scope.value == scope
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => c.scope.value = scope,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 13,
                            ),
                            child: Text(
                              (scope == 'mine'
                                      ? 'erp_task_mine'
                                      : 'erp_task_accessible')
                                  .tr,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: c.scope.value == scope
                                    ? AppColors.primaryDark
                                    : AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: c.searchController,
            onChanged: (value) => c.searchQuery.value = value,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'erp_task_search'.tr,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.muted,
                size: 22,
              ),
              suffixIcon: Obx(
                () => c.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'erp_task_clear_search'.tr,
                        icon: const Icon(Icons.close, size: 19),
                        onPressed: () {
                          c.searchController.clear();
                          c.searchQuery.value = '';
                        },
                      ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.dividerMint),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.dividerMint),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => PopupMenuButton<TaskListFilter>(
                    tooltip: 'erp_task_filter_status'.tr,
                    initialValue: c.filter.value,
                    onSelected: (value) => c.filter.value = value,
                    itemBuilder: (_) => TaskListFilter.values
                        .map(
                          (value) => CheckedPopupMenuItem(
                            value: value,
                            checked: c.filter.value == value,
                            child: Row(
                              children: [
                                Expanded(child: Text(c.filterLabel(value))),
                                if (!c.isLoading.value &&
                                    c.errorMessage.value.isEmpty &&
                                    _count(value, c.summary.value) != null)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 16,
                                    ),
                                    child: Text(
                                      '${_count(value, c.summary.value)}',
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.dividerMint),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune,
                            size: 18,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.filterLabel(c.filter.value),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.expand_more,
                            size: 18,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Obx(
                () => c.showEmployeeFilter
                    ? const SizedBox(width: 10)
                    : const SizedBox.shrink(),
              ),
              TaskEmployeeFilterBar(controller: c),
            ],
          ),
        ],
      ),
    );
  }

  static int? _count(TaskListFilter filter, TaskSummary summary) =>
      switch (filter) {
        TaskListFilter.all => summary.totalItems,
        TaskListFilter.open => summary.openCount,
        TaskListFilter.working => summary.workingCount,
        TaskListFilter.review => summary.pendingReviewCount,
        TaskListFilter.completed => summary.completedCount,
        TaskListFilter.overdue => summary.overdueCount,
        _ => null,
      };
}

class _TaskMessage extends StatelessWidget {
  const _TaskMessage({this.error = false, this.reason, this.onRetry});
  final bool error;
  final String? reason;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
    child: Column(
      children: [
        Icon(
          error ? Icons.cloud_off_outlined : Icons.task_alt_outlined,
          size: 44,
          color: error ? AppColors.muted : AppColors.primary,
        ),
        const SizedBox(height: 16),
        Text(
          (error ? 'failed_load_tasks' : 'no_tasks').tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error
              ? (reason ?? 'erp_task_load_help'.tr)
              : 'erp_task_empty_help'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (error) ...[
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('erp_task_retry'.tr),
          ),
        ],
      ],
    ),
  );
}
