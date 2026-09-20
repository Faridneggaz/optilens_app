import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/user_dashboard_controller.dart';
import '../../widgets/header.dart';
import '../../widgets/stock/document_ui.dart';
import '../../widgets/stock/stock_entry_card.dart';

class StockEntryListPage extends StatefulWidget {
  const StockEntryListPage({super.key});

  @override
  State<StockEntryListPage> createState() => _StockEntryListPageState();
}

class _StockEntryListPageState extends State<StockEntryListPage> {
  static const _statuses = [
    'All',
    'Draft',
    'Pending',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<UserDashboardController>().fetchStockEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<UserDashboardController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        body: Column(
          children: [
            AppHeader(
                title: 'nav_stock_entries'.tr,
                customer: null,
                customerCode: ''),
            Obx(() => DocumentFilterBar(
                  hint: 'search_stock_hint'.tr,
                  statuses: _statuses,
                  selectedStatus: c.selectedStatus.value,
                  searchController: c.searchController,
                  onSearchChanged: (v) => c.searchQuery.value = v,
                  onStatusChanged: (v) => c.selectedStatus.value = v,
                )),
            Expanded(
              child: Obx(() {
                if ((c.isLoading.value && !c.isLoadingMore.value) ||
                    c.isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (c.filteredEntries.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: c.onRefresh,
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Text('no_stock_entries'.tr,
                              style: const TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: c.onRefresh,
                  color: AppColors.primary,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    itemCount: c.filteredEntries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == c.filteredEntries.length) {
                        return DocumentLoadMoreFooter(
                          hasMore: c.hasMore.value,
                          isLoadingMore: c.isLoadingMore.value,
                          hasItems: c.stockEntries.isNotEmpty,
                          isSearching: c.searchQuery.value.isNotEmpty,
                          onLoadMore: c.onLoadMore,
                        );
                      }
                      return StockEntryCard(
                        entry: c.filteredEntries[index],
                        controller: c,
                      );
                    },
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
