// ignore_for_file: annotate_overrides
import '../../core/network/api_client.dart';
import '../../domain/entities/item.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/order_repository.dart';
import '../mappers/json_mappers.dart';

class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._client);

  final ApiClient _client;

  Future<List<Item>> fetchItems(String customerCode) async {
    final data = await _client.postMobile(
      'get_items_by_customer_code',
      attachToken: false,
      body: {'customer_code': customerCode},
    );
    final msg = data['message'];
    if (msg == null) throw const RepositoryException('Empty response');
    if (msg is! Map || msg['status'] != 'success') {
      throw RepositoryException(
        (msg is Map ? msg['message']?.toString() : null) ??
            'Failed to load items',
      );
    }
    final rawItems = msg['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((e) => ItemMapper.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  }) async {
    if (searchText.isEmpty) return [];
    try {
      final data = await _client.postMobile(
        'search_items',
        attachToken: false,
        body: {
          'search_text': searchText,
          'customer_code': customerCode,
        },
      );
      List rawItems = [];
      final message = data['message'];
      if (message is List) {
        rawItems = message;
      } else if (message is Map && message['items'] is List) {
        rawItems = message['items'] as List;
      }
      return rawItems
          .map((e) => ItemMapper.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> submitOrder({
    required List<Map<String, dynamic>> items,
  }) async {
    final decoded = await _client.postCustomerMethod('create_sales_order', body: {'items': items});
    final msg = _client.unwrap(decoded);
    if (msg == null) {
      throw const RepositoryException('Null message in response');
    }
    if (msg is Map &&
        (msg['status'] == 'success' || msg['order_id'] != null)) {
      return true;
    }
    final errorMsg =
        (msg is Map ? msg['message'] : null) ?? 'Erreur inconnue du serveur';
    throw RepositoryException(errorMsg.toString());
  }

  Future<List<dynamic>> fetchOrders() async {
    final data = await _client.getCustomerMethod('get_customer_orders');
    final msg = _client.unwrap(data);
    if (msg is Map && msg['orders'] is List) return msg['orders'] as List;
    throw const RepositoryException('Failed to load orders');
  }

  Future<List<dynamic>?> getOrderItems(String orderId) async {
    final data = await _client.getCustomerMethod(
      'get_order_details',
      query: {'order_id': orderId},
    );
    final msg = _client.unwrap(data);
    if (msg is Map && msg['status'] == 'success') {
      return msg['items'] as List<dynamic>?;
    }
    throw RepositoryException(msg is Map ? msg['message']?.toString() ?? 'Order not found' : 'Order not found');
  }
}
