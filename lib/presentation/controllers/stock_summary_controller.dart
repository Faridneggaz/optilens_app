import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/services/session_service.dart';
import '../../domain/entities/stock_summary.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';

enum StockQtyFilter { positive, all, negative }

class StockSummaryController extends GetxController {
  StockSummaryController({
    StockEntryUseCases? stock,
    MaterialRequestUseCases? materialRequests,
  })  : _stock = stock ?? Get.find<StockEntryUseCases>(),
        _materialRequests =
            materialRequests ?? Get.find<MaterialRequestUseCases>();

  final StockEntryUseCases _stock;
  final MaterialRequestUseCases _materialRequests;

  final items = <StockSummaryItem>[].obs;
  final summary = const StockSummaryTotals(
    totalItems: 0,
    totalQty: 0,
    lowStockCount: 0,
  ).obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final searchQuery = ''.obs;
  final selectedWarehouse = 'All'.obs;
  final qtyFilter = StockQtyFilter.all.obs;
  final onlyLowStock = false.obs;
  final warehouses = <String>['All'].obs;

  final searchController = TextEditingController();
  Worker? _debounce;
  int _offset = 0;
  static const int _limit = 20;

  String get _token => Get.find<SessionService>().authToken;

  @override
  void onInit() {
    super.onInit();
    _debounce = debounce(searchQuery, (_) => onRefresh(),
        time: const Duration(milliseconds: 400));
    ever(selectedWarehouse, (_) => onRefresh());
    ever(qtyFilter, (_) => onRefresh());
    ever(onlyLowStock, (_) => onRefresh());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadWarehouses();
    await onRefresh();
  }

  Future<void> _loadWarehouses() async {
    final allowed = Get.find<SessionService>().getAllowedWarehouses();
    if (allowed.isNotEmpty) {
      warehouses.value = ['All', ...allowed];
      return;
    }
    try {
      final companies = await _materialRequests.fetchCompanies(token: _token);
      final company =
          companies.isNotEmpty ? companies.first : 'OPTILENS ALGER';
      final rows = await _materialRequests.fetchWarehouses(
        token: _token,
        company: company,
      );
      final names = rows
          .map((w) => w['name'] ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      warehouses.value = ['All', ...names];
    } catch (_) {
      warehouses.value = ['All'];
    }
  }

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    hasMore.value = true;
    _offset = 0;
    items.clear();
    await fetchSummary();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchSummary(isLoadMore: true);
    }
  }

  Future<void> fetchSummary({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else if (items.isEmpty) {
        isLoading.value = true;
      }

      final filter = qtyFilter.value;
      final response = await _stock.fetchStockSummary(
        token: _token,
        limit: _limit,
        offset: _offset,
        searchText: searchQuery.value.trim().isEmpty
            ? null
            : searchQuery.value.trim(),
        warehouse: selectedWarehouse.value == 'All'
            ? null
            : selectedWarehouse.value,
        onlyInStock: filter == StockQtyFilter.positive,
        onlyNegative: filter == StockQtyFilter.negative,
        includeLowStockOnly: onlyLowStock.value,
      );

      // Server returns already-filtered items + summary.
      summary.value = response.summary;

      if (isLoadMore) {
        items.addAll(response.items);
      } else {
        items.value = response.items;
      }

      hasMore.value = response.hasMore;
      if (response.items.isNotEmpty) {
        _offset += response.items.length;
      }
    } catch (e) {
      if (e is RepositoryException && e.message.isNotEmpty) {
        Get.snackbar(
          'error'.tr,
          e.message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      } else {
        ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_stock_summary');
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  String formatQty(double qty) {
    if (qty == qty.roundToDouble()) return qty.toInt().toString();
    return qty.toStringAsFixed(2);
  }

  String qtyFilterLabel(StockQtyFilter filter) {
    switch (filter) {
      case StockQtyFilter.positive:
        return 'stock_filter_positive'.tr;
      case StockQtyFilter.all:
        return 'stock_filter_all'.tr;
      case StockQtyFilter.negative:
        return 'stock_filter_negative'.tr;
    }
  }
}
