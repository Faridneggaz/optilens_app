import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../application/controllers/order_controller.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<OrderController>();
    // Clear any previous cart state when page opens
    c.cart.clear();

    const Color primaryTeal = Color(0xFF008075);
    const Color darkBlue    = Color(0xFF1F2837);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FFFD),
      appBar: AppBar(
        title: const Text('NOUVELLE COMMANDE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: primaryTeal),
      ),
      body: Column(children: [
        // ── Search bar ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: SearchAnchor(
            viewBackgroundColor: const Color(0xFFF7FFFD),
            viewElevation: 0,
            viewShape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(25))),
            builder: (context, controller) => SearchBar(
              controller: controller,
              hintText: 'Chercher un verre ou une monture...',
              onTap:     () => controller.openView(),
              onChanged: (_) => controller.openView(),
              leading: const Icon(Icons.search, color: primaryTeal),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                  primaryTeal.withValues(alpha: 0.05)),
            ),
            suggestionsBuilder: (context, controller) async {
              final results = await c.searchItems(controller.text);
              if (results.isEmpty && controller.text.length >= 2) {
                return [const ListTile(title: Text('Aucun article trouvé'))];
              }
              return results.map((item) => ListTile(
                    leading: const Icon(Icons.lens,
                        color: primaryTeal, size: 12),
                    title: Text(item['item_code'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['standard_rate'] ?? 0} DZD'),
                    onTap: () {
                      c.addToCart(item);
                      controller.closeView(item['item_code']);
                    },
                  ));
            },
          ),
        ),

        // ── Cart list ────────────────────────────────────────────────────────
        Expanded(
          child: Obx(() => c.cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_basket_outlined,
                          size: 50, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text('Votre panier est vide',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: c.cart.length,
                  itemBuilder: (context, i) =>
                      _buildCartTile(c, i, primaryTeal),
                )),
        ),

        // ── Summary / Confirm ─────────────────────────────────────────────
        _buildSummary(c, primaryTeal, darkBlue),
      ]),
    );
  }

  Widget _buildCartTile(
      OrderController c, int index, Color primaryTeal) {
    final item = c.cart[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10)
        ],
      ),
      child: ListTile(
        title: Text(item['item_code'],
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('${item['rate']} DZD',
            style: TextStyle(
                color: primaryTeal, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              onPressed: () => c.updateQty(index, -1),
            ),
            Text('${item['qty']}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon:      Icon(Icons.add_circle_outline, color: primaryTeal),
              onPressed: () => c.updateQty(index, 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(
      OrderController c, Color primaryTeal, Color darkBlue) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Obx(() => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL ESTIMÉ',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text('${c.cartTotal.toStringAsFixed(2)} DZD',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: primaryTeal)),
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
                            'Succès',
                            'Commande envoyée avec succès !',
                            backgroundColor: Colors.green,
                            colorText:       Colors.white,
                          );
                          Get.back();
                        } else {
                          Get.snackbar(
                            'Erreur',
                            'Erreur de création de commande',
                            backgroundColor: Colors.red,
                            colorText:       Colors.white,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: c.isSubmitting.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('VALIDER LA COMMANDE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            )),
      ]),
    );
  }
}