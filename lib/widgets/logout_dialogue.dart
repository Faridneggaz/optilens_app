import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/session_service.dart';
import '../app/routes/app_routes.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color.fromARGB(255, 247, 255, 253),
        surfaceTintColor: Color.fromARGB(255, 247, 255, 253),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'logout_confirm_title'.tr,
          style: const TextStyle(
            color: Color(0xFF1F2837),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'btn_cancel'.tr,
              style: const TextStyle(
                color: Color(0xFF008075),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 223, 54, 38),
              foregroundColor: Color.fromARGB(255, 247, 255, 253),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await Get.find<SessionService>().clearSession();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text(
              'btn_confirm'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}