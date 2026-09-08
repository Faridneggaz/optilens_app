import 'package:get/get.dart';
import '../../data/repositories/material_request_repository.dart';
import '../../data/repositories/employee_api.dart';
import '../../domain/response/material_request_response.dart';
import '../../core/services/session_service.dart';

class MaterialRequestListController extends GetxController {
  final _repo = MaterialRequestRepository();

  final materialRequests = <MaterialRequest>[].obs;
  final searchResults    = <MaterialRequest>[].obs;
  final isLoading        = true.obs;
  final isLoadingMore    = false.obs;
  final hasMore          = true.obs;
  final searchQuery      = ''.obs;
  final isSearching      = false.obs;
  final selectedStatus   = 'All'.obs;

  Worker? _debounce;
  int _offset = 0;
  static const int _limit = 20;

  String get _token => Get.find<SessionService>().authToken;

  List<MaterialRequest> get displayList =>
      searchQuery.value.trim().isEmpty ? materialRequests : searchResults;

  @override
  void onInit() {
    super.onInit();
    fetchMaterialRequests();
    _debounce = debounce(
      searchQuery,
      (String q) => _searchFromServer(q),
      time: const Duration(milliseconds: 400),
    );
  }

  @override
  void onClose() {
    _debounce?.dispose();
    super.onClose();
  }

  Future<void> _searchFromServer(String q) async {
    if (q.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      final result = await _repo.fetchMaterialRequests(
        token:      _token,
        searchText: q.trim(),
        status:     selectedStatus.value != 'All' ? selectedStatus.value : null,
      );
      searchResults.value = result.materialRequests;
    } catch (_) {
      // silently fail — UI shows empty state
    } finally {
      isSearching.value = false;
    }
  }

  Future<void> fetchMaterialRequests({bool isLoadMore = false}) async {
    try {
      if (isLoadMore) {
        isLoadingMore.value = true;
      } else {
        isLoading.value = true;
        _offset         = 0;
      }
      final response = await _repo.fetchMaterialRequests(
        token:  _token,
        limit:  _limit,
        offset: _offset,
        status: selectedStatus.value != 'All' ? selectedStatus.value : null,
      );
      if (isLoadMore) {
        materialRequests.addAll(response.materialRequests);
      } else {
        materialRequests.value = response.materialRequests;
      }
      if (response.materialRequests.length < _limit) {
        hasMore.value = false;
      } else {
        _offset      += _limit;
        hasMore.value = true;
      }
    } catch (_) {
      // silently fail — UI shows empty state
    } finally {
      isLoading.value     = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> onRefresh() async {
    hasMore.value = true;
    _offset       = 0;
    materialRequests.clear();
    await fetchMaterialRequests();
  }

  Future<void> onLoadMore() async {
    if (!isLoadingMore.value && hasMore.value) {
      await fetchMaterialRequests(isLoadMore: true);
    }
  }

  Future<Map<String, dynamic>> submitRequest(String name) async {
    try {
      return await _repo.manageMaterialRequest(
          token: _token, name: name, action: 'submit');
    } catch (e) {
      return EmployeeApi.failureResult(e);
    }
  }

  Future<Map<String, dynamic>> cancelRequest(String name) async {
    try {
      return await _repo.manageMaterialRequest(
          token: _token, name: name, action: 'cancel');
    } catch (e) {
      return EmployeeApi.failureResult(e);
    }
  }

  Future<Map<String, dynamic>> deleteRequest(String name) async {
    try {
      return await _repo.manageMaterialRequest(
          token: _token, name: name, action: 'delete');
    } catch (e) {
      return EmployeeApi.failureResult(e);
    }
  }

  Future<List<Map<String, String>>> searchItems(String searchText) async {
    try {
      return await _repo.searchItems(token: _token, searchText: searchText);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchDetail(String name) async {
    try {
      final mr = await _repo.fetchDetail(token: _token, name: name);
      return {
        'success': true,
        'material_request': mr,
      };
    } catch (e) {
      return EmployeeApi.failureResult(e);
    }
  }

  Future<Map<String, dynamic>> createRequest({
    required String company,
    required String purpose,
    required String requiredBy,
    required String setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      return await _repo.createMaterialRequest(
        token:             _token,
        company:           company,
        purpose:           purpose,
        requiredBy:        requiredBy,
        setWarehouse:      setWarehouse,
        setFromWarehouse:  setFromWarehouse,
        priceList:         priceList,
        items:             items,
      );
    } catch (e) {
      return EmployeeApi.failureResult(e);
    }
  }
}
