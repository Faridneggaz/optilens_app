import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/cart_item.dart';
import '../../presentation/controllers/order_controller.dart';

class OrderCartTile extends StatelessWidget {
  const OrderCartTile({
    super.key,
    required this.controller,
    required this.index,
  });

  final OrderController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final CartItem item = controller.cart[index];
    return Obx(() {
      final qty = controller.cart.isNotEmpty && index < controller.cart.length
          ? controller.cart[index].quantity
          : 0;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.rate.toStringAsFixed(2)} x $qty'
                      '  =  '
                      '${(item.rate * qty).toStringAsFixed(2)} ${item.currency}',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.redAccent, size: 22),
                    onPressed: () => controller.updateQty(index, -1),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primaryDark, size: 22),
                    onPressed: () => controller.updateQty(index, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
