import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/session_service.dart';
import '../app/routes/app_routes.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Do you really want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await Get.find<SessionService>().clearSession();
              Get.offAllNamed(AppRoutes.login);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }
}
