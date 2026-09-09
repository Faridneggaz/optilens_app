import '../entities/item.dart';

abstract class OrderRepository {
  Future<List<Item>> fetchItems(String customerCode);

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  });

  Future<bool> submitOrder({
    required String customerCode,
    required List<Map<String, dynamic>> items,
  });

  Future<List<dynamic>> fetchOrders(String customerCode);

  Future<List<dynamic>?> getOrderItems(String orderId);
}
