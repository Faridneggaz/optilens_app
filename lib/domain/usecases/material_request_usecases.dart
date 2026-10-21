import '../entities/material_request_response.dart';
import '../repositories/material_request_repository.dart';
import '../results/action_result.dart';

class MaterialRequestUseCases {
  MaterialRequestUseCases(this._repo);
  final MaterialRequestRepository _repo;

  Future<MaterialRequestResponse> fetchMaterialRequests({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  }) =>
      _repo.fetchMaterialRequests(
        token: token,
        limit: limit,
        offset: offset,
        searchText: searchText,
        status: status,
      );

  Future<MaterialRequest> fetchDetail({
    required String token,
    required String name,
  }) =>
      _repo.fetchDetail(token: token, name: name);

  Future<List<Map<String, String>>> fetchWarehouses({
    required String token,
    required String company,
  }) =>
      _repo.fetchWarehouses(token: token, company: company);

  Future<List<String>> fetchCompanies({required String token}) =>
      _repo.fetchCompanies(token: token);

  Future<List<String>> fetchPriceLists({required String token}) =>
      _repo.fetchPriceLists(token: token);

  Future<ActionResult> createMaterialRequest({
    required String token,
    required String company,
    required String purpose,
    required String requiredBy,
    String? setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final map = await _repo.createMaterialRequest(
        token: token,
        company: company,
        purpose: purpose,
        requiredBy: requiredBy,
        setWarehouse: setWarehouse,
        setFromWarehouse: setFromWarehouse,
        priceList: priceList,
        items: items,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<ActionResult> manageMaterialRequest({
    required String token,
    required String name,
    required String action,
  }) async {
    try {
      final map = await _repo.manageMaterialRequest(
        token: token,
        name: name,
        action: action,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<ActionResult> createStockEntryFromMR({
    required String token,
    required String name,
    String? purpose,
  }) async {
    try {
      final map = await _repo.createStockEntryFromMR(
        token: token,
        name: name,
        purpose: purpose,
      );
      return ActionResult.fromApiMap(map);
    } catch (e) {
      return ActionResult.fromException(e);
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) =>
      _repo.searchItems(token: token, searchText: searchText);
}
