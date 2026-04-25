import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/response/customer.dart';
import '../../app/routes/app_routes.dart';

/// Global singleton that holds the current user/client session.
/// Registered with Get.put() in main.dart so it is always available.
class SessionController extends GetxController {
  final customer   = Rxn<Customer>();
  final token      = ''.obs;
  final userName   = ''.obs;
  final isUser     = false.obs;

  /// Shared ZoomDrawer controller so ZoomDrawerPage can be a StatelessWidget.
  final zoomDrawerCtrl = ZoomDrawerController();

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    customer.value  = null;
    token.value     = '';
    userName.value  = '';
    isUser.value    = false;
    Get.offAllNamed(AppRoutes.login);
  }
}
