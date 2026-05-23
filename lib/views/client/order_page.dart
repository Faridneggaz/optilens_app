import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/order_controller.dart';
import '../../../application/controllers/language_controller.dart';
import '../../domain/response/cart_item.dart';
import '../../domain/response/item.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _teal     = Color(0xFF008075);
  static const Color _darkBlue = Color(0xFF1F2837);
  static const Color _bg       = Color(0xFFF7FFFD);

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrderController>();
    // cart.clear() is now called by clearCart() via the BindingsBuilder in
    // main.dart — fires once per route push, not on every rebuild.

    return GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: Text(
            'new_order'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(color: _teal),
        ),
        body: Column(children: [
          // ── Search bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: SearchAnchor(
              viewBackgroundColor: _bg,
              viewElevation: 0,
              viewShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
              ),
              builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: 'search_item_bar_hint'.tr,
                onTap:     () => controller.openView(),
                onChanged: (_) => controller.openView(),
                leading: const Icon(Icons.search, color: _teal),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  _teal.withValues(alpha: 0.05),
                ),
              ),

              // ✅ FIX : Future<List<Widget>> — compatible avec suggestionsBuilder
              suggestionsBuilder: (context, controller) async {
                final q = controller.text.trim();

                if (q.isEmpty) {
                  return [
                    ListTile(
                      leading: const Icon(Icons.search, color: Colors.grey),
                      title: Text('search_item_hint'.tr),
                    )
                  ];
                }

                // ✅ Appel direct à search_items via le controller
                final results = await c.searchItems(q);

                if (results.isEmpty) {
                  return [
                    ListTile(
                      leading: const Icon(Icons.info_outline, color: Colors.orange),
                      title: Text('no_item_found'.tr),
                    )
                  ];
                }

                return results
                    .map((item) => _buildSuggestionTile(c, item, controller))
                    .toList();
              },
            ),
          ),

          // ── Cart list ──────────────────────────────────────────────────────
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
                            style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                            'cart_empty_hint'.tr,
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    itemCount: c.cart.length,
                    itemBuilder: (context, i) => _buildCartTile(c, i),
                  )),
          ),

          // ── Summary / Confirm ──────────────────────────────────────────────
          _buildSummary(c, context),
        ]),
      ),
    );
  }

  // ── Search suggestion tile ───────────────────────────────────────────────

  Widget _buildSuggestionTile(
    OrderController c,
    Item item,
    SearchController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
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
            color: _teal,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: _teal),
          onPressed: () {
            c.addToCart(item);
            controller.closeView(item.itemName);
          },
        ),
        onTap: () {
          c.addToCart(item);
          controller.closeView(item.itemName);
        },
      ),
    );
  }

  // ── Cart item tile ───────────────────────────────────────────────────────

  Widget _buildCartTile(OrderController c, int index) {
    final CartItem item = c.cart[index];
    return Obx(() {
      final qty = c.cart.isNotEmpty && index < c.cart.length
          ? c.cart[index].quantity
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
                        color: _darkBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.rate.toStringAsFixed(2)} × $qty'
                      '  =  '
                      '${(item.rate * qty).toStringAsFixed(2)} ${item.currency}',
                      style: const TextStyle(
                        color: _teal,
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
                    onPressed: () => c.updateQty(index, -1),
                  ),
                  Text(
                    '$qty',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: _teal, size: 22),
                    onPressed: () => c.updateQty(index, 1),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ── Summary panel ────────────────────────────────────────────────────────

  Widget _buildSummary(OrderController c, BuildContext context) {
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
                  '${'total_prefix'.tr}${c.cartTotal.toStringAsFixed(2)} DZD',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _teal,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 20),
        Obx(() => SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: c.isSubmitting.value
                    ? null
                    : () async {
                        final ok = await c.confirmOrder();
                        if (ok) {
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
                            'order_error'.tr,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: c.isSubmitting.value
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