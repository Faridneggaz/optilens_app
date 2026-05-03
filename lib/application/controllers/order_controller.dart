import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/response/item.dart';
import '../../domain/response/cart_item.dart';

class OrderController extends GetxController {
  final _repo = OrderRepository();

  // ── Item catalogue state ─────────────────────────────────────────────────

  /// All items available to this customer (customer-specific pricing).
  final items          = <Item>[].obs;
  final isLoadingItems = true.obs;

  /// Text entered in the search bar — updated by the view.
  final searchQuery = ''.obs;

  /// Subset of [items] matching [searchQuery] (case-insensitive).
  List<Item> get filteredItems {
    final q = searchQuery.value.toLowerCase().trim();
    if (q.isEmpty) return items;
    return items
        .where((i) =>
            i.itemCode.toLowerCase().contains(q) ||
            i.itemName.toLowerCase().contains(q))
        .toList();
  }

  // ── Cart state ───────────────────────────────────────────────────────────

  final cart         = <CartItem>[].obs;
  final isSubmitting = false.obs;

  double get cartTotal =>
      cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  // ── Order-history state ──────────────────────────────────────────────────

  final orders    = [].obs;
  final isLoading = false.obs;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    final code = Get.find<SessionService>().userCode;
    if (code.isNotEmpty) _fetchItems(code);
  }

  // ── Item loading ─────────────────────────────────────────────────────────

  Future<void> _fetchItems(String customerCode) async {
    isLoadingItems.value = true;
    try {
      items.value = await _repo.fetchItems(customerCode);
    } catch (_) {
      items.value = [];
    } finally {
      // ✅ Toujours remis à false même en cas d'erreur
      isLoadingItems.value = false;
    }
  }

  // ── Item search ──────────────────────────────────────────────────────────

  /// ✅ Nouvelle fonction — appelle l'endpoint search_items directement
  /// Utilisée par la SearchAnchor pour des résultats rapides côté serveur
  Future<List<Item>> searchItems(String searchText) async {
    if (searchText.trim().isEmpty) return [];
    try {
      return await _repo.searchItems(searchText.trim());
    } catch (_) {
      return [];
    }
  }

  // ── Cart management ──────────────────────────────────────────────────────

  void addToCart(Item item) {
    final idx = cart.indexWhere((e) => e.itemCode == item.itemCode);
    if (idx != -1) {
      cart[idx].quantity++;
      cart.refresh();
    } else {
      cart.add(CartItem(
        itemCode: item.itemCode,
        itemName: item.itemName,
        rate:     item.rate,
        currency: item.currency,
        uom:      item.uom,
      ));
    }
  }

  void updateQty(int index, int delta) {
    if (delta < 0 && cart[index].quantity == 1) {
      cart.removeAt(index);
    } else {
      cart[index].quantity += delta;
      cart.refresh();
    }
  }

  /// Called once per route entry (via BindingsBuilder in main.dart)
  /// to ensure the user always starts a new order with a fresh cart.
  void clearCart() => cart.clear();

  // ── Order submission ─────────────────────────────────────────────────────

  Future<bool> confirmOrder() async {
    if (cart.isEmpty) return false;
    isSubmitting.value = true;
    try {
      final payload = cart.map((item) => item.toJson()).toList();
      final result  = await _repo.submitOrder(payload);
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

  Future<List<dynamic>?> getOrderItems(String orderId) async {
    try {
      return await _repo.getOrderItems(orderId);
    } catch (_) {
      return null;
    }
  }
}