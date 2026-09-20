import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/task_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/stock/document_ui.dart';
import '../../widgets/task/task_card.dart';

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
      if (Get.isRegistered<TaskController>()) {
        Get.find<TaskController>().onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TaskController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            Obx(() => AppHeader(
                  title: 'nav_my_tasks'.tr,
                  customer: null,
                  customerCode: '',
                  subtitle: c.displayDate,
                )),
            _SearchAndFilters(controller: c),
            Expanded(
              child: Obx(() {
                if (c.isLoading.value && c.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 4, 0, 24),
                    children: [
                      _SummaryStrip(controller: c),
                      if (c.items.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.12,
                          ),
                          child: Center(
                            child: Text(
                              c.filter.value == TaskListFilter.today
                                  ? 'no_tasks_today'.tr
                                  : 'no_tasks'.tr,
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else ...[
                        ...c.items.map(
                          (task) => TaskCard(task: task, controller: c),
                        ),
                        DocumentLoadMoreFooter(
                          hasMore: c.hasMore.value,
                          isLoadingMore: c.isLoadingMore.value,
                          hasItems: c.items.isNotEmpty,
                          isSearching: c.searchQuery.value.isNotEmpty,
                          onLoadMore: c.onLoadMore,
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller.searchController,
                    onChanged: (v) => controller.searchQuery.value = v,
                    decoration: InputDecoration(
                      hintText: 'search_tasks_hint'.tr,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TaskListFilter.values.map((f) {
                  final selected = controller.filter.value == f;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(controller.filterLabel(f)),
                      selected: selected,
                      onSelected: (_) => controller.filter.value = f,
                      selectedColor: AppColors.primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primaryDark
                            : AppColors.body,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            _SummaryCell(label: 'tasks_open'.tr, value: '${s.openCount}'),
            const SizedBox(width: 8),
            _SummaryCell(
              label: 'tasks_overdue'.tr,
              value: '${s.overdueCount}',
              emphasize: s.overdueCount > 0,
            ),
            const SizedBox(width: 8),
            _SummaryCell(label: 'tasks_closed'.tr, value: '${s.closedCount}'),
          ],
        ),
      );
    });
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: emphasize ? AppColors.dangerSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: emphasize
                ? AppColors.danger.withValues(alpha: 0.25)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: emphasize ? AppColors.danger : AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: emphasize ? AppColors.danger : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
