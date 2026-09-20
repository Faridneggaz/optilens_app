import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/usecases/usecases.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../utils/error_feedback.dart';
import 'stock_summary_controller.dart';
import 'material_request_controller.dart';
import 'task_controller.dart';

class UserDashboardController extends GetxController {
  UserDashboardController({StockEntryUseCases? stock})
      : _stock = stock ?? Get.find<StockEntryUseCases>();

  final StockEntryUseCases _stock;

  final stockEntries    = <StockEntry>[].obs;
  final isLoading       = true.obs;
  final isLoadingMore   = false.obs;
  final hasMore         = true.obs;
  final selectedPageIndex = 0.obs;
  final searchQuery     = ''.obs;
  final selectedStatus  = 'All'.obs;
  final isSearching     = false.obs;
  final searchStockEntries = <StockEntry>[].obs;
  Worker? _debounce;

  int _offset = 0;
  static const int _limit = 20;

  final searchController = TextEditingController();

  @override
  void onClose() {
    _debounce?.dispose();
    searchController.dispose();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    
    _debounce = debounce(searchQuery, (query) {
      if (query.isNotEmpty) {
        fetchSearchResults();
      } else {
        isSearching.value = false;
        searchStockEntries.clear();
      }
    }, time: const Duration(milliseconds: 400));

    ever(selectedStatus, (_) {
      if (searchQuery.value.isNotEmpty) {
        fetchSearchResults();
      } else {
        onRefresh();
      }
    });

    _loadToken();
  }

  Future<void> _loadToken() async {
    fetchStockEntries();
  }

  void setPage(int i) {
    selectedPageIndex.value = i;
    if (i == 2) {
      fetchStockEntries();
    }
    if (i == 3 && Get.isRegistered<MaterialRequestController>()) {
      Get.find<MaterialRequestController>().onRefresh();
    }
    if (i == 4 && Get.isRegistered<StockSummaryController>()) {
      Get.find<StockSummaryController>().onRefresh();
    }
    if (i == 5 && Get.isRegistered<TaskController>()) {
      Get.find<TaskController>().onRefresh();
    }
  }

  List<StockEntry> get filteredEntries {
    return searchQuery.value.isNotEmpty ? searchStockEntries : stockEntries;
  }

  Future<void> onRefresh() async {
    isLoading.value = true;
    hasMore.value   = true;
    _offset         = 0;
    stockEntries.clear();
    await fetchStockEntries();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchStockEntries(isLoadMore: true);
    }
  }

  Future<void> fetchStockEntries({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else if (stockEntries.isEmpty) {
        isLoading.value = true;
      }

      final response = await _stock.fetchLastStockEntries(
        token: Get.find<SessionService>().authToken,
        limit: _limit,
        offset: _offset,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );

      if (isLoadMore) {
        stockEntries.addAll(response.stockEntries);
      } else {
        stockEntries.value = response.stockEntries;
      }

      if (response.stockEntries.length < _limit) {
        hasMore.value = false;
      } else {
        _offset += _limit;
      }
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'failed_load_stock');
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> fetchSearchResults() async {
    isSearching.value = true;
    try {
      final response = await _stock.fetchLastStockEntries(
        token: Get.find<SessionService>().authToken,
        limit: 20,
        offset: 0,
        searchText: searchQuery.value,
        status: selectedStatus.value == 'All' ? null : selectedStatus.value,
      );
      searchStockEntries.value = response.stockEntries;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_search_stock');
    } finally {
      isSearching.value = false;
    }
  }

  void navigateToStockEntry(String name) {
    Get.toNamed(AppRoutes.stockEntry, arguments: {
      'name':  name,
    });
  }
}
