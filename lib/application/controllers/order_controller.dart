import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../data/repositories/order_repository.dart';
import '../../utils/api_config.dart';

class OrderController extends GetxController {
  final _repo = OrderRepository();

  // Cart state (used by OrderPage)
  final cart         = <Map<String, dynamic>>[].obs;
  final isSubmitting = false.obs;

  // Order history state (used by OrderHistoryPage)
  final orders    = [].obs;
  final isLoading = false.obs;

  double get cartTotal =>
      cart.fold(0, (sum, item) => sum + (item['rate'] * item['qty']));

  // ── Cart management ──────────────────────────────────────────────────────

  void addToCart(dynamic item) {
    final idx = cart.indexWhere((e) => e['item_code'] == item['item_code']);
    if (idx != -1) {
      cart[idx]['qty']++;
      cart.refresh();
    } else {
      cart.add({
        'item_code': item['item_code'],
        'item_name': item['item_name'] ?? item['item_code'],
        'qty':       1,
        'rate':      (item['standard_rate'] ?? 0.0).toDouble(),
      });
    }
  }

  void updateQty(int index, int delta) {
    if (delta < 0 && cart[index]['qty'] == 1) {
      cart.removeAt(index);
    } else {
      cart[index]['qty'] += delta;
      cart.refresh();
    }
  }

  // ── Item search (no token needed for this endpoint) ─────────────────────

  Future<List<dynamic>> searchItems(String query) async {
    if (query.length < 2) return [];
    try {
      final url =
          '${ApiConfig.apiMethodPath}mobile_app.api.search_items?search_text=$query';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // ── Order submission ─────────────────────────────────────────────────────

  Future<bool> confirmOrder() async {
    if (cart.isEmpty) return false;
    isSubmitting.value = true;
    try {
      final result = await _repo.submitOrder(cart.toList());
      if (result) cart.clear();
      return result;
    } catch (_) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Order history ────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    isLoading.value = true;
    try {
      orders.value = await _repo.fetchOrders();
    } catch (_) {
      orders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<List?> getOrderItems(String orderId) async {
    try {
      return await _repo.getOrderItems(orderId);
    } catch (_) {
      return null;
    }
  }
}