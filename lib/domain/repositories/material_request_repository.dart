import '../entities/material_request_response.dart';

abstract class MaterialRequestRepository {
  Future<MaterialRequestResponse> fetchMaterialRequests({
    required String token,
    int limit = 20,
    int offset = 0,
    String? searchText,
    String? status,
  });

  Future<MaterialRequest> fetchDetail({
    required String token,
    required String name,
  });

  Future<List<Map<String, String>>> fetchWarehouses({
    required String token,
    required String company,
  });

  Future<List<String>> fetchCompanies({required String token});

  Future<List<String>> fetchPriceLists({required String token});

  Future<Map<String, dynamic>> createMaterialRequest({
    required String token,
    required String company,
    required String purpose,
    required String requiredBy,
    required String setWarehouse,
    String? setFromWarehouse,
    String? priceList,
    required List<Map<String, dynamic>> items,
  });

  Future<Map<String, dynamic>> manageMaterialRequest({
    required String token,
    required String name,
    required String action,
  });

  Future<Map<String, dynamic>> createStockEntryFromMR({
    required String token,
    required String name,
  });

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  });
}
