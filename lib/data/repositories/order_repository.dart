import '../../core/network/api_client.dart';
import '../../domain/response/item.dart';
import 'repository_exception.dart';

class OrderRepository {
  OrderRepository(this._client);

  final ApiClient _client;

  Future<List<Item>> fetchItems(String customerCode) async {
    final data = await _client.getMobile(
      'get_items_by_customer_code',
      query: {'customer_code': customerCode},
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
        .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<Item>> searchItems({
    required String searchText,
    required String customerCode,
  }) async {
    if (searchText.isEmpty) return [];
    try {
      final data = await _client.getMobile(
        'search_items',
        query: {
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
          .map((e) => Item.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> submitOrder({
    required String customerCode,
    required List<Map<String, dynamic>> items,
  }) async {
    if (customerCode.isEmpty) {
      throw const RepositoryException('Customer code not found in session');
    }
    final decoded = await _client.postMobile(
      'create_sales_order',
      body: {
        'customer_code': customerCode,
        'items': items,
        'token': _client.currentToken,
      },
      attachToken: false,
    );
    final msg = decoded['message'];
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

  Future<List<dynamic>> fetchOrders(String customerCode) async {
    if (customerCode.isEmpty) {
      throw const RepositoryException('Customer code not found in session');
    }
    final data = await _client.getMobile(
      'get_customer_orders',
      query: {'customer_code': customerCode},
    );
    return (data['message']?['orders'] as List<dynamic>?) ?? [];
  }

  Future<List<dynamic>?> getOrderItems(String orderId) async {
    final data = await _client.getMobile(
      'get_order_details',
      query: {'order_id': orderId},
    );
    final msg = data['message'];
    if (msg is Map && msg['status'] == 'success') {
      return msg['items'] as List<dynamic>?;
    }
    return null;
  }
}
