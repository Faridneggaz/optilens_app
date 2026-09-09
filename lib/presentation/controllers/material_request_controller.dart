import 'package:get/get.dart';
import '../../domain/entities/material_request_response.dart';
import '../../domain/usecases/usecases.dart';
import '../../core/services/session_service.dart';
import '../../domain/results/action_result.dart';
import '../../utils/error_feedback.dart';

class MaterialRequestController extends GetxController {
  MaterialRequestController({MaterialRequestUseCases? materialRequests})
      : _materialRequests =
            materialRequests ?? Get.find<MaterialRequestUseCases>();

  final MaterialRequestUseCases _materialRequests;

  final materialRequests = <MaterialRequest>[].obs;
  final searchResults    = <MaterialRequest>[].obs;
  final isLoading        = true.obs;
  final isLoadingMore    = false.obs;
  final hasMore          = true.obs;
  final searchQuery      = ''.obs;
  final isSearching      = false.obs;
  final selectedStatus   = 'All'.obs;
  final warehouses       = <Map<String, String>>[].obs;
  final companies        = <String>[].obs;
  final priceLists       = <String>[].obs;

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
    _initLookups();
    _debounce = debounce(
      searchQuery,
      (String q) => _searchFromServer(q),
      time: const Duration(milliseconds: 400),
    );
  }

  Future<void> _initLookups() async {
    await loadCompanies();
    final company = companies.isNotEmpty ? companies.first : 'OPTILENS ALGER';
    await loadWarehouses(company);
  }

  Future<void> loadCompanies() async {
    try {
      final res = await _materialRequests.fetchCompanies(token: _token);
      if (res.isNotEmpty) {
        companies.value = res;
        return;
      }
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_material_requests');
    }
    final allowed = Get.find<SessionService>().getAllowedCompanies();
    if (allowed.isNotEmpty) {
      companies.value = allowed;
    }
  }

  Future<void> loadPriceLists() async {
    try {
      priceLists.value = await _materialRequests.fetchPriceLists(token: _token);
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_material_requests');
    }
  }

  @override
  void onClose() {
    _debounce?.dispose();
    super.onClose();
  }

  Future<void> loadWarehouses(String company) async {
    try {
      final res = await _materialRequests.fetchWarehouses(token: _token, company: company);
      warehouses.value = res;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_material_requests');
    }
  }

  Future<void> _searchFromServer(String q) async {
    if (q.trim().isEmpty) {
      searchResults.clear();
      return;
    }
    isSearching.value = true;
    try {
      final result = await _materialRequests.fetchMaterialRequests(
        token:      _token,
        searchText: q.trim(),
        status:     selectedStatus.value != 'All' ? selectedStatus.value : null,
      );
      searchResults.value = result.materialRequests;
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_material_requests');
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
      final response = await _materialRequests.fetchMaterialRequests(
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
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_material_requests');
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
    if (!isLoadingMore.value && hasMore.value && searchQuery.value.isEmpty) {
      await fetchMaterialRequests(isLoadMore: true);
    }
  }

  Future<ActionResult> submitRequest(String name) {
    return _materialRequests.manageMaterialRequest(
      token: _token,
      name: name,
      action: 'submit',
    );
  }

  Future<ActionResult> deleteRequest(String name) {
    return _materialRequests.manageMaterialRequest(
      token: _token,
      name: name,
      action: 'delete',
    );
  }

  Future<List<Map<String, String>>> searchItems(String searchText) async {
    try {
      return await _materialRequests.searchItems(
        token: _token,
        searchText: searchText,
      );
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'no_item_found');
      return [];
    }
  }

  Future<ActionResult> createRequest({
    required String company,
    required String purpose,
    required String requiredBy,
    required String setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) {
    return _materialRequests.createMaterialRequest(
      token: _token,
      company: company,
      purpose: purpose,
      requiredBy: requiredBy,
      setWarehouse: setWarehouse,
      setFromWarehouse: setFromWarehouse,
      priceList: priceList,
      items: items,
    );
  }
}
