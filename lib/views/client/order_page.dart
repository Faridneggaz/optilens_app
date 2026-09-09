import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/controllers/language_controller.dart';
import '../../presentation/controllers/order_controller.dart';
import '../../widgets/order/order_cart_tile.dart';
import '../../widgets/order/order_search_section.dart';
import '../../widgets/order/order_summary_bar.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrderController>();

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text(
            'new_order'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          backgroundColor: AppColors.scaffold,
          elevation: 0,
          leading: const BackButton(color: AppColors.primaryDark),
        ),
        body: Column(children: [
          OrderSearchSection(controller: c),
          Expanded(
            child: Obx(() => c.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('cart_empty'.tr,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'cart_empty_hint'.tr,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    itemCount: c.cart.length,
                    itemBuilder: (context, i) =>
                        OrderCartTile(controller: c, index: i),
                  )),
          ),
          OrderSummaryBar(controller: c),
        ]),
      ),
    );
  }
}
