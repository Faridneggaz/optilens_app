import '../entities/item.dart';
import '../repositories/order_repository.dart';

class OrderUseCases {
  OrderUseCases(this._repo);
  final OrderRepository _repo;

  Future<List<Item>> fetchItems(String customerCode) =>
      _repo.fetchItems(customerCode);

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  }) =>
      _repo.searchItems(searchText: searchText, customerCode: customerCode);

  Future<bool> submitOrder({
    required String customerCode,
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.submitOrder(customerCode: customerCode, items: items);

  Future<List<dynamic>> fetchOrders(String customerCode) =>
      _repo.fetchOrders(customerCode);

  Future<List<dynamic>?> getOrderItems(String orderId) =>
      _repo.getOrderItems(orderId);
}
