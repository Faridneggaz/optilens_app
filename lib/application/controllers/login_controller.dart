import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/login_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/employee_api.dart';
import '../../app/routes/app_routes.dart';
import '../../core/services/session_service.dart';
import 'session_controller.dart';

class LoginController extends GetxController {
  final _loginRepo    = LoginRepository();
  final _customerRepo = CustomerRepository();

  // Form controllers — disposed in onClose
  final clientCodeController = TextEditingController();
  final emailController      = TextEditingController();
  final passwordController   = TextEditingController();

  // Reactive state
  final isLoading    = false.obs;
  final isUserLogin  = false.obs;
  final isObscure    = true.obs;
  final errorMessage = ''.obs;

  @override
  void onClose() {
    clientCodeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleLoginMode() {
    isUserLogin.value = !isUserLogin.value;
    errorMessage.value = '';
  }
  void toggleObscure()    => isObscure.value     = !isObscure.value;

  Future<void> loginClient() async {
    final code = clientCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('error'.tr, 'error_enter_client_code'.tr,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final response = await _customerRepo.fetchCustomer(code);
      
      final sessionService = Get.find<SessionService>();
      await sessionService.saveSession(
        code: code,
        role: 'client',
        token: '',
      );

      final session = Get.find<SessionController>();
      session.customer.value = response.customer;
      session.isUser.value   = false;

      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage.value = 'connection_error'.tr;
      } else {
        errorMessage.value = 'incorrect_code'.tr;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser() async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('error'.tr, 'error_email_password_required'.tr,
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final response = await _loginRepo.login(email: email, password: password);
      final sid = response.user.sid;

      if (sid.isEmpty) {
        errorMessage.value = 'error_token_missing'.tr;
        return;
      }

      EmployeeApi.resetAuthGuards();

      final sessionService = Get.find<SessionService>();
      await sessionService.saveSession(
        code: response.user.email ?? email,
        role: 'user',
        token: sid,
      );
      
      await sessionService.saveUserPermissions(
        response.user.allowedCompanies,
        response.user.allowedWarehouses,
      );

      final session = Get.find<SessionController>();
      session.token.value    = sid;
      session.userName.value = response.user.name ?? 'Utilisateur';
      session.isUser.value   = true;

      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('socket') || errorStr.contains('connection')) {
        errorMessage.value = 'connection_error'.tr;
      } else {
        errorMessage.value = 'login_error'.tr;
      }
    } finally {
      isLoading.value = false;
    }
  }
}