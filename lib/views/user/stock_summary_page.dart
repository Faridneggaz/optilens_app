import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/stock_summary.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/stock_summary_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/stock/document_ui.dart';

class StockSummaryPage extends StatefulWidget {
  const StockSummaryPage({super.key});

  @override
  State<StockSummaryPage> createState() => _StockSummaryPageState();
}

class _StockSummaryPageState extends State<StockSummaryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<StockSummaryController>()) {
        Get.find<StockSummaryController>().onRefresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<StockSummaryController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            AppHeader(
              title: 'nav_stock_summary'.tr,
              customer: null,
              customerCode: '',
            ),
            _FilterRow(controller: c),
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
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
                    children: [
                      _SummaryHeader(controller: c),
                      if (c.items.isEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.12,
                          ),
                          child: Center(
                            child: Text(
                              'no_stock_summary'.tr,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else ...[
                        ...c.items.map((item) => _StockSummaryCard(
                              item: item,
                              controller: c,
                            )),
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

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.controller});

  final StockSummaryController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: controller.searchController,
                          decoration: InputDecoration(
                            hintText: 'search_stock_summary_hint'.tr,
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                          onChanged: (v) => controller.searchQuery.value = v,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => FilterChip(
                    selected: controller.onlyLowStock.value,
                    label: Text('low_stock_filter'.tr),
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange.shade800,
                    onSelected: (v) => controller.onlyLowStock.value = v,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Obx(() => _DropdownBox(
                      value: controller.selectedWarehouse.value,
                      items: controller.warehouses.toList(),
                      labelBuilder: (v) =>
                          v == 'All' ? 'all_warehouses'.tr : v,
                      onChanged: (v) {
                        if (v != null) {
                          controller.selectedWarehouse.value = v;
                        }
                      },
                    )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => _DropdownBox(
                      value: controller.qtyFilter.value.name,
                      items: StockQtyFilter.values.map((e) => e.name).toList(),
                      labelBuilder: (v) {
                        final filter = StockQtyFilter.values.firstWhere(
                          (e) => e.name == v,
                          orElse: () => StockQtyFilter.all,
                        );
                        return controller.qtyFilterLabel(filter);
                      },
                      onChanged: (v) {
                        if (v == null) return;
                        controller.qtyFilter.value =
                            StockQtyFilter.values.firstWhere(
                          (e) => e.name == v,
                          orElse: () => StockQtyFilter.all,
                        );
                      },
                    )),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DropdownBox extends StatelessWidget {
  const _DropdownBox({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelBuilder,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String) labelBuilder;

  @override
  Widget build(BuildContext context) {
    final safeValue = items.contains(value)
        ? value
        : (items.isNotEmpty ? items.first : value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.isEmpty ? null : safeValue,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    labelBuilder(e),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.controller});

  final StockSummaryController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.summary.value;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'summary_items'.tr,
                    value: '${s.totalItems}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'summary_qty'.tr,
                    value: controller.formatQty(s.totalQty),
                  ),
                ),
              ],
            ),
            if (s.lowStockCount > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.orange.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'low_stock_banner'
                            .trParams({'count': '${s.lowStockCount}'}),
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockSummaryCard extends StatelessWidget {
  const _StockSummaryCard({
    required this.item,
    required this.controller,
  });

  final StockSummaryItem item;
  final StockSummaryController controller;

  @override
  Widget build(BuildContext context) {
    return DocumentListCard(
      onTap: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.isLowStock) ...[
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'low_stock_badge'.tr,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              Text(
                '${controller.formatQty(item.qty)} ${item.uom}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: item.qty < 0
                      ? Colors.red.shade700
                      : AppColors.primaryDark,
                ),
              ),
            ],
          ),
          if (item.warehouse.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.warehouse_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.warehouse,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
