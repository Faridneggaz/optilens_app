import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/stock_entry_repository.dart';
import '../../domain/response/stock_entry.dart';
import '../../app/routes/app_routes.dart';
import 'session_controller.dart';

class UserDashboardController extends GetxController {
  final _repo    = StockEntryRepository();
  final _session = Get.find<SessionController>();

  final stockEntries    = <StockEntry>[].obs;
  final isLoading       = true.obs;
  final isLoadingMore   = false.obs;
  final hasMore         = true.obs;
  final selectedPageIndex = 0.obs;
  final searchQuery     = ''.obs;
  final selectedStatus  = 'All'.obs;

  int _offset = 0;
  static const int _limit = 20;
  String _actualToken = '';

  @override
  void onInit() {
    super.onInit();
    _loadToken();
  }

  Future<void> _loadToken() async {
    if (_session.token.value.isNotEmpty) {
      _actualToken = _session.token.value;
    } else {
      final prefs = await SharedPreferences.getInstance();
      _actualToken = prefs.getString('token') ?? '';
    }
    fetchStockEntries();
  }

  void setPage(int i) => selectedPageIndex.value = i;

  List<StockEntry> get filteredEntries {
    return stockEntries.where((e) {
      final matchSearch = e.name.toLowerCase().contains(searchQuery.value.toLowerCase());
      final matchStatus = selectedStatus.value == 'All' ||
          e.status.toLowerCase() == selectedStatus.value.toLowerCase();
      return matchSearch && matchStatus;
    }).toList();
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

      final response = await _repo.fetchLastStockEntries(
        token: _actualToken,
        limit: _limit,
        offset: _offset,
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
      // silently fail — UI shows empty state
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  void navigateToStockEntry(String name) {
    Get.toNamed(AppRoutes.stockEntry, arguments: {
      'name':  name,
      'token': _actualToken,
    });
  }
}
