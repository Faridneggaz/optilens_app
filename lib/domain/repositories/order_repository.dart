import '../entities/item.dart';

abstract class OrderRepository {
  Future<List<Item>> fetchItems(String customerCode);

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  });

  Future<bool> submitOrder({
    required List<Map<String, dynamic>> items,
  });

  Future<List<dynamic>> fetchOrders();

  Future<List<dynamic>?> getOrderItems(String orderId);
}
