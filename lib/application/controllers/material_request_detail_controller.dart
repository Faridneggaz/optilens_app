import 'package:get/get.dart';
import '../../data/repositories/material_request_repository.dart';
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
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitRequest() async {
    try {
      await _repo.manageMaterialRequest(token: _token, name: mrName, action: 'submit');
      await fetchDetail();
    } catch (e) {
      errorMessage.value = e.toString();
    }
  }
}
