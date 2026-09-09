import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../application/controllers/session_controller.dart';
import '../../domain/response/customer.dart';
import '../../core/theme/app_colors.dart';

/// Waits for a restored client session before building pages that need [Customer].
class ClientSessionGate extends StatelessWidget {
  const ClientSessionGate({super.key, required this.builder});

  final Widget Function(Customer customer) builder;

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    return Obx(() {
      final customer = session.customer.value;
      if (session.isRestoring.value || customer == null) {
        return const Scaffold(
          backgroundColor: AppColors.scaffold,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return builder(customer);
    });
  }
}
