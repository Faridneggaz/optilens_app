import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/usecases.dart';
import '../../app/routes/app_routes.dart';
import '../../core/auth/auth_events.dart';
import '../../core/services/session_service.dart';
import '../../domain/results/action_result.dart';
import '../../utils/error_feedback.dart';
import 'session_controller.dart';

class LoginController extends GetxController {
  LoginController({required AuthUseCases auth}) : _auth = auth;

  final AuthUseCases _auth;

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
      final response = await _auth.fetchCustomer(code);
      
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
      errorMessage.value = ErrorFeedback.isNetwork(e)
          ? 'connection_error'.tr
          : 'incorrect_code'.tr;
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
      final response = await _auth.login(email: email, password: password);
      final sid = response.user.sid;

      AuthEvents.resetGuards();

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
    } on MissingTokenException {
      errorMessage.value = 'error_token_missing'.tr;
    } catch (e) {
      errorMessage.value = ErrorFeedback.isNetwork(e)
          ? 'connection_error'.tr
          : 'login_error'.tr;
    } finally {
      isLoading.value = false;
    }
  }
}