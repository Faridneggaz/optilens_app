import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/repositories/login_repository.dart';
import '../../data/repositories/customer_repository.dart';
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

  @override
  void onClose() {
    clientCodeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void toggleLoginMode()  => isUserLogin.value  = !isUserLogin.value;
  void toggleObscure()    => isObscure.value     = !isObscure.value;

  Future<void> loginClient() async {
    final code = clientCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Erreur', 'Veuillez entrer le code client',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
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
      Get.snackbar('Erreur', 'Code client invalide',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginUser() async {
    final email    = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('Erreur', 'Email et mot de passe requis',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    isLoading.value = true;
    try {
      final response = await _loginRepo.login(email: email, password: password);
      
      if (response.user.sid.isEmpty) {
        Get.snackbar('Erreur', 'Token manquant dans la réponse',
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final sessionService = Get.find<SessionService>();
      await sessionService.saveSession(
        code: response.user.email ?? email,
        role: 'user',
        token: response.user.sid,
      );

      final session = Get.find<SessionController>();
      session.token.value    = response.user.sid;
      session.userName.value = response.user.name ?? 'Utilisateur';
      session.isUser.value   = true;

      Get.offAllNamed(AppRoutes.main);
    } catch (e) {
      Get.snackbar('Erreur', 'Identifiants invalides',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}