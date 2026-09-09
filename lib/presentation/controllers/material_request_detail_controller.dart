import 'package:get/get.dart';
import '../../domain/entities/material_request_response.dart';
import '../../domain/failures/failures.dart';
import '../../domain/results/action_result.dart';
import '../../domain/usecases/usecases.dart';
import '../../core/services/session_service.dart';

class MaterialRequestDetailController extends GetxController {
  MaterialRequestDetailController(
    this.mrName, {
    MaterialRequestUseCases? materialRequests,
  }) : _materialRequests =
            materialRequests ?? Get.find<MaterialRequestUseCases>();

  final MaterialRequestUseCases _materialRequests;

  final mr = Rxn<MaterialRequest>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final String mrName;

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
      mr.value =
          await _materialRequests.fetchDetail(token: _token, name: mrName);
    } catch (e) {
      if (e is! InvalidSessionException && e is! AccessDeniedException) {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<ActionResult> submitRequest() async {
    final res = await _materialRequests.manageMaterialRequest(
      token: _token,
      name: mrName,
      action: 'submit',
    );
    if (res.isSuccess) await fetchDetail();
    if (!res.isAuthHandled && !res.isSuccess) {
      errorMessage.value = res.error ?? '';
    }
    return res;
  }

  Future<ActionResult> createTransfer() async {
    final res = await _materialRequests.createStockEntryFromMR(
      token: _token,
      name: mrName,
    );
    if (!res.isAuthHandled && !res.isSuccess) {
      errorMessage.value = res.error ?? '';
    }
    return res;
  }
}
