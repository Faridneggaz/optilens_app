import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/session_service.dart';
import '../app/routes/app_routes.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // heavily rounded corners
        ),
        title: Text('logout_confirm_title'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'btn_cancel'.tr,
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              await Get.find<SessionService>().clearSession();
              Get.offAllNamed(AppRoutes.login);
            },
            child: Text('btn_confirm'.tr),
          ),
        ],
      ),
    );
  }
}


