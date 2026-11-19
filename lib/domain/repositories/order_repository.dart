import '../entities/item.dart';

abstract class OrderRepository {
  Future<List<Item>> fetchItems();

  Future<List<Item>> searchItems({
    required String searchText,
  });

  Future<bool> submitOrder({
    required List<Map<String, dynamic>> items,
  });

  Future<List<dynamic>> fetchOrders();

  Future<List<dynamic>?> getOrderItems(String orderId);
}
