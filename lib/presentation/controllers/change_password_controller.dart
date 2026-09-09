import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/usecases.dart';
import 'session_controller.dart';
import '../../core/services/session_service.dart';
import '../../core/theme/app_colors.dart';

class ChangePasswordController extends GetxController {
  ChangePasswordController({AuthUseCases? auth})
      : _auth = auth ?? Get.find<AuthUseCases>();

  final AuthUseCases _auth;

  final oldPassword     = ''.obs;
  final newPassword     = ''.obs;
  final confirmPassword = ''.obs;
  final isLoading       = false.obs;
  final errorMessage    = ''.obs;
  final isSuccess       = false.obs;
  final obscureOld      = true.obs;
  final obscureNew      = true.obs;
  final obscureConfirm  = true.obs;

  Future<void> changePassword() async {
    errorMessage.value = '';

    if (oldPassword.value.trim().isEmpty ||
        newPassword.value.trim().isEmpty ||
        confirmPassword.value.trim().isEmpty) {
      errorMessage.value = 'fields_required'.tr;
      return;
    }
    if (newPassword.value.trim() != confirmPassword.value.trim()) {
      errorMessage.value = 'passwords_do_not_match'.tr;
      return;
    }
    if (newPassword.value.trim() == oldPassword.value.trim()) {
      errorMessage.value = 'new_password_same_as_old'.tr;
      return;
    }

    isLoading.value = true;
    try {
      final result = await _auth.changePassword(
        oldPassword: oldPassword.value.trim(),
        newPassword: newPassword.value.trim(),
      );

      if (result.success) {
        final service = Get.find<SessionService>();
        await service.saveSession(
          code:  newPassword.value.trim(),
          role:  service.userRole,
          token: service.authToken,
        );
        Get.find<SessionController>().userName.value = newPassword.value.trim();

        isSuccess.value = true;
        Get.snackbar(
          'success'.tr,
          'password_changed_successfully'.tr,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
        );
        await Future.delayed(const Duration(seconds: 3));
        Get.back();

      } else {
        final error = result.error ?? '';
        if (error.contains('Customer not found') ||
            error.contains('not found')) {
          errorMessage.value = 'incorrect_current_password'.tr;
        } else if (error.contains('already used') ||
                   error.contains('already')) {
          errorMessage.value = 'new_password_already_used'.tr;
        } else if (error.isNotEmpty) {
          errorMessage.value = error;
        } else {
          errorMessage.value = 'error_occurred'.tr;
        }
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
