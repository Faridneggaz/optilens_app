import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../application/controllers/change_password_controller.dart';
import '../../../application/controllers/language_controller.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ChangePasswordController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'change_password'.tr,
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'change_your_password'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'enter_old_and_new_password'.tr,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildPasswordField(
                    label: 'current_password'.tr,
                    obscureText: c.obscureOld.value,
                    onToggleVisibility: () => c.obscureOld.toggle(),
                    onChanged: (v) => c.oldPassword.value = v,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: 'new_password'.tr,
                    obscureText: c.obscureNew.value,
                    onToggleVisibility: () => c.obscureNew.toggle(),
                    onChanged: (v) => c.newPassword.value = v,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    label: 'confirm_new_password'.tr,
                    obscureText: c.obscureConfirm.value,
                    onToggleVisibility: () => c.obscureConfirm.toggle(),
                    onChanged: (v) => c.confirmPassword.value = v,
                  ),
                  const SizedBox(height: 12),
                  if (c.errorMessage.value.isNotEmpty)
                    Text(
                      c.errorMessage.value,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: c.isLoading.value ? null : c.changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 167, 155),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: c.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'confirm'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Function(String) onChanged,
  }) {
    return TextField(
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 0, 167, 155)),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }
}
