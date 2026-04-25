import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../utils/payment_utils.dart';
import '../../../application/controllers/payment_controller.dart';
import '../../../application/controllers/session_controller.dart';

class PaymentPage extends StatelessWidget {
  PaymentPage({super.key});

  final PaymentController c = Get.find<PaymentController>();

  @override
  Widget build(BuildContext context) {
    final customer = Get.find<SessionController>().customer.value!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 255, 253, 1),
      body: Column(
        children: [
          AppHeader(
              title: '',
              customer: customer,
              customerCode: customer.code),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.payments.isEmpty) {
                return const Center(child: Text('No payments found'));
              }
              return SingleChildScrollView(
                child: PaymentList(
                  globalTitle: 'Payments History',
                  items: c.payments,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
