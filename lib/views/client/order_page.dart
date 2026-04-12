import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../application/controllers/order_controller.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final OrderController _orderController = OrderController();
  final List<Map<String, dynamic>> _cart = [];
  bool _isSubmitting = false;

  final Color primaryTeal = const Color(0xFF008075);
  final Color darkBlue = const Color(0xFF1F2837);

  double get _total => _cart.fold(0, (sum, item) => sum + (item['rate'] * item['qty']));

  Future<List<dynamic>> _searchItems(String query) async {
    if (query.length < 2) return [];
    try {
      final String url = "http://192.168.0.100:8000/api/method/mobile_app.api.search_items?search_text=$query";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? [];
      }
    } catch (e) {
      debugPrint("Erreur recherche: $e");
    }
    return [];
  }

  void _addToCart(dynamic item) {
    setState(() {
      int index = _cart.indexWhere((e) => e['item_code'] == item['item_code']);
      if (index != -1) {
        _cart[index]['qty']++;
      } else {
        _cart.add({
          "item_code": item['item_code'],
          "item_name": item['item_name'] ?? item['item_code'],
          "qty": 1,
          "rate": (item['standard_rate'] ?? 0.0).toDouble(),
        });
      }
    });
  }

  void _confirmOrder() async {
    if (_cart.isEmpty) return;
    setState(() => _isSubmitting = true);

    bool success = await _orderController.submitOrder(_cart);

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Commande envoyée avec succès !"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur de création de commande"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FFFD),
      appBar: AppBar(
        title: const Text("NOUVELLE COMMANDE",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: primaryTeal),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SearchAnchor(
              builder: (context, controller) => SearchBar(
                controller: controller,
                hintText: "Chercher un verre ou une monture...",
                onTap: () => controller.openView(),
                onChanged: (_) => controller.openView(),
                leading: Icon(Icons.search, color: primaryTeal),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor:
                    WidgetStatePropertyAll(primaryTeal.withOpacity(0.05)),
              ),
              suggestionsBuilder: (context, controller) async {
                final results = await _searchItems(controller.text);
                if (results.isEmpty && controller.text.length >= 2) {
                  return [const ListTile(title: Text("Aucun article trouvé"))];
                }
                return results
                    .map((item) => ListTile(
                          leading:
                              Icon(Icons.lens, color: primaryTeal, size: 12),
                          title: Text(item['item_code'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle:
                              Text("${item['standard_rate'] ?? 0} DZD"),
                          onTap: () {
                            _addToCart(item);
                            controller.closeView(item['item_code']);
                          },
                        ))
                    .toList();
              },
            ),
          ),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_basket_outlined,
                            size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        const Text("Votre panier est vide",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) => _buildCartTile(index),
                  ),
          ),
          _buildSummarySection(),
        ],
      ),
    );
  }

  Widget _buildCartTile(int index) {
    final item = _cart[index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
        ],
      ),
      child: ListTile(
        title: Text(item['item_code'],
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text("${item['rate']} DZD",
            style: TextStyle(
                color: primaryTeal, fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: Colors.redAccent),
              onPressed: () => setState(() =>
                  item['qty'] > 1 ? item['qty']-- : _cart.removeAt(index)),
            ),
            Text("${item['qty']}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: primaryTeal),
              onPressed: () => setState(() => item['qty']++),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL ESTIMÉ",
                  style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
              Text("${_total.toStringAsFixed(2)} DZD",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: primaryTeal)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _confirmOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("VALIDER LA COMMANDE",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}