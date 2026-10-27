import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/activity_report.dart';
import '../../presentation/controllers/activity_report_list_controller.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/activity_report/report_widgets.dart';

class ActivityReportListPage extends StatelessWidget {
  const ActivityReportListPage({super.key});
  Future<void> _open(ActivityReportListController c, {String? name}) async {
    if (name != null) {
      await Get.toNamed(
        AppRoutes.activityReportDetail,
        arguments: {'name': name},
      );
    } else {
      final result = await Get.toNamed(AppRoutes.activityReportForm);
      if (result is ActivityReportResult &&
          result.canRead &&
          result.report != null) {
        await Get.toNamed(
          AppRoutes.activityReportDetail,
          arguments: {'name': result.report!.name},
        );
      }
    }
    if (!c.isClosed) await c.refreshReports();
  }

  Future<void> _filters(
    BuildContext context,
    ActivityReportListController c,
  ) async {
    String type = c.type.value,
        from = c.fromDate.value,
        to = c.toDate.value,
        error = '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ar_filters'.tr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'ar_close'.tr,
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(type),
                initialValue: type,
                isExpanded: true,
                decoration: InputDecoration(labelText: 'ar_type'.tr),
                items: ['', 'Weekly Report', 'Monthly Report']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t.isEmpty ? 'ar_all_types'.tr : reportTypeLabel(t),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => type = v!),
              ),
              const SizedBox(height: 14),
              ReportDateField(
                label: 'ar_from'.tr,
                value: from,
                onChanged: (v) => setState(() => from = v),
              ),
              ReportDateField(
                label: 'ar_to'.tr,
                value: to,
                onChanged: (v) => setState(() => to = v),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    error,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  if (from.isNotEmpty &&
                      to.isNotEmpty &&
                      from.compareTo(to) > 0) {
                    setState(() => error = 'ar_dates_invalid'.tr);
                    return;
                  }
                  c.applyFilters(type, from, to);
                  Navigator.pop(sheetContext);
                },
                child: Text('ar_apply'.tr),
              ),
              TextButton(
                onPressed: () {
                  c.applyFilters('', '', '');
                  Navigator.pop(sheetContext);
                },
                child: Text('ar_reset'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ActivityReportListController>();
    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        floatingActionButton: Obx(
          () => c.canCreate.value
              ? FloatingActionButton.extended(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  onPressed: () => _open(c),
                  icon: const Icon(Icons.add),
                  label: Text('ar_new'.tr),
                )
              : const SizedBox.shrink(),
        ),
        body: Column(
          children: [
            AppHeader(title: 'ar_reports'.tr, customer: null, customerCode: ''),
            Expanded(
              child: RefreshIndicator(
                onRefresh: c.refreshReports,
                child: Obx(
                  () => ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: c.searchController,
                              onChanged: (v) => c.search.value = v,
                              textInputAction: TextInputAction.search,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'ar_search'.tr,
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.dividerMint,
                                  ),
                                ),
                                suffixIcon: c.search.value.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'ar_clear'.tr,
                                        onPressed: () {
                                          c.searchController.clear();
                                          c.search.value = '';
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: 'ar_filters'.tr,
                            style: IconButton.styleFrom(
                              backgroundColor: c.hasFilters
                                  ? AppColors.primary
                                  : AppColors.dividerMint,
                              foregroundColor: c.hasFilters
                                  ? Colors.white
                                  : AppColors.primaryDark,
                            ),
                            onPressed: () => _filters(context, c),
                            icon: const Icon(Icons.tune),
                          ),
                        ],
                      ),
                      if (c.hasFilters)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  [
                                    if (c.type.value.isNotEmpty)
                                      reportTypeLabel(c.type.value),
                                    if (c.fromDate.value.isNotEmpty)
                                      '${'ar_from'.tr} ${c.fromDate.value}',
                                    if (c.toDate.value.isNotEmpty)
                                      '${'ar_to'.tr} ${c.toDate.value}',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'ar_reset'.tr,
                                onPressed: () => c.applyFilters('', '', ''),
                                icon: const Icon(Icons.close, size: 18),
                              ),
                            ],
                          ),
                        ),
                      if (c.loading.value)
                        const Padding(
                          padding: EdgeInsets.all(60),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (c.items.isEmpty && c.error.value.isNotEmpty)
                        ReportErrorPanel(
                          message: c.error.value,
                          retry: c.refreshReports,
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 4,
                          ),
                          child: Text(
                            '${'ar_reports'.tr} (${c.total.value})',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (c.items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 45),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'ar_empty'.tr,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ar_empty_help'.tr,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...c.items.map(
                          (r) => Card(
                            color: Colors.white,
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(
                                color: AppColors.dividerMint,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _open(c, name: r.name),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        Text(
                                          reportTypeLabel(r.type),
                                          style: const TextStyle(
                                            color: AppColors.primaryDark,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (r.date.isNotEmpty)
                                          Text(
                                            r.date,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        Text(
                                          '${r.actionCount} ${'ar_actions_count'.tr}',
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (c.error.value.isNotEmpty)
                          ReportErrorPanel(
                            message: c.error.value,
                            retry: c.loadMore,
                          )
                        else if (c.loadingMore.value)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (c.hasMore.value)
                          OutlinedButton(
                            onPressed: c.loadMore,
                            child: Text('ar_load_more'.tr),
                          ),
                      ],
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
