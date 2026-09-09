import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/entities/item.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/failures/failures.dart';
import '../../domain/usecases/usecases.dart';
import '../../utils/error_feedback.dart';

class OrderController extends GetxController {
  OrderController({OrderUseCases? orders})
      : _orders = orders ?? Get.find<OrderUseCases>();

  final OrderUseCases _orders;

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

  Future<void> _fetchItems(String code) async {
    isLoadingItems.value = true;
    try {
      items.value = await _orders.fetchItems(code);
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'load_error');
      items.value = [];
    } finally {
      isLoadingItems.value = false;
    }
  }

  String get _customerCode => Get.find<SessionService>().userCode;

  Future<List<Item>> searchItems(String searchText) async {
    if (searchText.trim().isEmpty) return [];
    try {
      return await _orders.searchItems(
        searchText: searchText.trim(),
        customerCode: _customerCode,
      );
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'no_item_found');
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

  Future<String?> confirmOrder() async {
    if (cart.isEmpty) return 'cart_empty'.tr;
    isSubmitting.value = true;
    try {
      final payload = cart.map((item) => item.toJson()).toList();
      final result = await _orders.submitOrder(
        customerCode: _customerCode,
        items: payload,
      );
      if (result) {
        cart.clear();
        return null;
      }
      return 'order_error'.tr;
    } catch (e) {
      if (e is RepositoryException) {
        return ErrorFeedback.isNetwork(e)
            ? 'connection_error'.tr
            : e.message;
      }
      return ErrorFeedback.message(e, fallbackKey: 'order_error');
    } finally {
      isSubmitting.value = false;
    }
  }

  // ── Order history ────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    isLoading.value = true;
    try {
      orders.value = await _orders.fetchOrders(_customerCode);
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_orders');
      orders.value = [];
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<dynamic>?> getOrderItems(String orderId) async {
    try {
      return await _orders.getOrderItems(orderId);
    } catch (e) {
      ErrorFeedback.snackbar(e, fallbackKey: 'error_load_orders');
      return null;
    }
  }
}