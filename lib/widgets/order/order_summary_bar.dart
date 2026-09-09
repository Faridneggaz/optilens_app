import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/order_controller.dart';

class OrderSummaryBar extends StatelessWidget {
  const OrderSummaryBar({super.key, required this.controller});

  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'estimated_total'.tr,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${'total_prefix'.tr}${controller.cartTotal.toStringAsFixed(2)} DZD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 20),
        Obx(() => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value
                    ? null
                    : () async {
                        final error = await controller.confirmOrder();
                        if (error == null) {
                          Get.snackbar(
                            'success'.tr,
                            'order_success'.tr,
                            backgroundColor: Colors.green,
                            colorText: Colors.white,
                          );
                          Get.back();
                        } else {
                          Get.snackbar(
                            'error'.tr,
                            error,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 5),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: controller.isSubmitting.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'confirm_order'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )),
      ]),
    );
  }
}
