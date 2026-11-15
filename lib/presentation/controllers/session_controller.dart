import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../../domain/entities/customer.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import '../../domain/usecases/usecases.dart';

/// Global singleton that holds the current user/client session.
/// Registered with Get.put() in main.dart so it is always available.
class SessionController extends GetxController {
  final customer = Rxn<Customer>();
  final token = ''.obs;
  final userName = ''.obs;
  final isUser = false.obs;
  final isRestoring = false.obs;

  /// Shared ZoomDrawer controller so ZoomDrawerPage can be a StatelessWidget.
  final zoomDrawerCtrl = ZoomDrawerController();

  /// Opens the side drawer from any screen (including pushed routes).
  void openDrawer() {
    void open() => zoomDrawerCtrl.open?.call();

    if (Get.currentRoute == AppRoutes.main) {
      open();
      return;
    }

    Get.until(
      (route) => route.settings.name == AppRoutes.main || route.isFirst,
    );

    Future.delayed(const Duration(milliseconds: 80), () {
      if (Get.currentRoute == AppRoutes.main) {
        open();
      }
    });
  }

  @override
  void onInit() {
    super.onInit();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final service = Get.find<SessionService>();
    if (service.isSessionValid()) {
      isUser.value = service.userRole == 'user';
      token.value = service.authToken;
      if (isUser.value) {
        userName.value = service.userDisplayName;
        await loadUserNameIfMissing();
      } else {
        isRestoring.value = true;
        try {
          final response = await Get.find<AuthUseCases>().fetchCustomer(
            service.userCode,
          );
          customer.value = response.customer;
        } catch (e) {
          await logout();
        } finally {
          isRestoring.value = false;
        }
      }
    }
  }

  Future<void> loadUserNameIfMissing() async {
    final service = Get.find<SessionService>();
    final sid = service.authToken;
    if (!isUser.value || sid.isEmpty || userName.value.isNotEmpty) return;

    try {
      final name = await Get.find<AuthUseCases>().fetchUserDisplayName(sid);
      if (name.isEmpty || service.authToken != sid || !isUser.value) return;
      await service.saveUserDisplayName(name);
      if (service.authToken == sid && isUser.value) {
        userName.value = service.userDisplayName;
      }
    } catch (_) {
      // The welcome screen can show a greeting while ERPNext is unreachable.
    }
  }

  Future<void> logout() async {
    final sessionService = Get.find<SessionService>();
    await sessionService.clearSession();
    customer.value = null;
    token.value = '';
    userName.value = '';
    isUser.value = false;
    Get.offAllNamed(AppRoutes.login);
  }
}
