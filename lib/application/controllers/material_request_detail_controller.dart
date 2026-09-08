import 'package:get/get.dart';
import '../../data/repositories/material_request_repository.dart';
import '../../data/repositories/employee_api.dart';
import '../../domain/response/material_request_response.dart';
import '../../core/services/session_service.dart';

class MaterialRequestDetailController extends GetxController {
  final _repo = MaterialRequestRepository();

  final mr           = Rxn<MaterialRequest>();
  final isLoading    = true.obs;
  final errorMessage = ''.obs;
  
  final String mrName;

  MaterialRequestDetailController(this.mrName);

  String get _token => Get.find<SessionService>().authToken;

  @override
  void onInit() {
    super.onInit();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final response = await _repo.fetchDetail(token: _token, name: mrName);
      mr.value = response;
    } catch (e) {
      if (!EmployeeApi.isAuthHandled(EmployeeApi.failureResult(e))) {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> submitRequest() async {
    try {
      final res = await _repo.manageMaterialRequest(token: _token, name: mrName, action: 'submit');
      await fetchDetail();
      return res;
    } catch (e) {
      final mapped = EmployeeApi.failureResult(e);
      if (!EmployeeApi.isAuthHandled(mapped)) {
        errorMessage.value = e.toString();
      }
      return mapped;
    }
  }

  Future<Map<String, dynamic>> createTransfer() async {
    try {
      final res = await _repo.createStockEntryFromMR(token: _token, name: mrName);
      return res;
    } catch (e) {
      final mapped = EmployeeApi.failureResult(e);
      if (!EmployeeApi.isAuthHandled(mapped)) {
        errorMessage.value = e.toString();
      }
      return mapped;
    }
  }
}
