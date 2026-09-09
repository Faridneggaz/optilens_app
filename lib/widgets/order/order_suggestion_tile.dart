import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/item.dart';
import '../../presentation/controllers/order_controller.dart';

class OrderSuggestionTile extends StatelessWidget {
  const OrderSuggestionTile({
    super.key,
    required this.controller,
    required this.item,
    required this.searchController,
  });

  final OrderController controller;
  final Item item;
  final SearchController searchController;

  void _add() {
    controller.addToCart(item);
    searchController.closeView(item.itemName);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          item.itemName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${item.rate.toStringAsFixed(2)} ${item.currency}',
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: AppColors.primaryDark),
          onPressed: _add,
        ),
        onTap: _add,
      ),
    );
  }
}
