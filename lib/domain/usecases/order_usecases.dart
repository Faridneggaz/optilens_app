import '../entities/item.dart';
import '../repositories/order_repository.dart';

class OrderUseCases {
  OrderUseCases(this._repo);
  final OrderRepository _repo;

  Future<List<Item>> fetchItems() => _repo.fetchItems();

  Future<List<Item>> searchItems({
    required String searchText,
  }) =>
      _repo.searchItems(searchText: searchText);

  Future<bool> submitOrder({
    required List<Map<String, dynamic>> items,
  }) =>
      _repo.submitOrder(items: items);

  Future<List<dynamic>> fetchOrders() =>
      _repo.fetchOrders();

  Future<List<dynamic>?> getOrderItems(String orderId) =>
      _repo.getOrderItems(orderId);
}
