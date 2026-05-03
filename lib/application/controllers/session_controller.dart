import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../../domain/response/customer.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/customer_repository.dart';

/// Global singleton that holds the current user/client session.
/// Registered with Get.put() in main.dart so it is always available.
class SessionController extends GetxController {
  final customer   = Rxn<Customer>();
  final token      = ''.obs;
  final userName   = ''.obs;
  final isUser     = false.obs;
  final isRestoring = false.obs;

  /// Shared ZoomDrawer controller so ZoomDrawerPage can be a StatelessWidget.
  final zoomDrawerCtrl = ZoomDrawerController();

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final service = Get.find<SessionService>();
    if (service.isSessionValid()) {
      isUser.value   = service.userRole == 'user';
      token.value    = service.authToken;
      userName.value = service.userCode;

      if (!isUser.value) {
        isRestoring.value = true;
        try {
          final response = await CustomerRepository().fetchCustomer(service.userCode);
          customer.value = response.customer;
        } catch (e) {
          await logout();
        } finally {
          isRestoring.value = false;
        }
      }
    }
  }

  Future<void> logout() async {
    final sessionService = Get.find<SessionService>();
    await sessionService.clearSession();
    customer.value  = null;
    token.value     = '';
    userName.value  = '';
    isUser.value    = false;
    Get.offAllNamed(AppRoutes.login);
  }
}
