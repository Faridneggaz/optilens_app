import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../core/services/session_service.dart';
import '../../domain/response/item.dart';
import '../../utils/api_config.dart';
import 'repository_exception.dart';

class OrderRepository {
  final String _baseUrl = ApiConfig.mobileAppApiPath;

  // ── Item catalogue ──────────────────────────────────────────────────────────

  Future<List<Item>> fetchItems(String customerCode) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/method/mobile_app.api.get_items_by_customer_code',
    ).replace(queryParameters: {'customer_code': customerCode});

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      final data = json.decode(response.body);
      final msg  = data['message'];
      if (msg == null) throw const RepositoryException('Empty response');
      if (msg['status'] != 'success') {
        throw RepositoryException(
            msg['message']?.toString() ?? 'Failed to load items');
      }
      final rawItems = msg['items'] as List<dynamic>? ?? [];
      return rawItems
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  // ── Item search ─────────────────────────────────────────────────────────────

  Future<List<Item>> searchItems(String searchText) async {
    if (searchText.isEmpty) return [];

    // ✅ Récupérer le customer_code depuis la session
    final code = Get.find<SessionService>().userCode;

    // ✅ Passer customer_code pour récupérer la bonne price list côté backend
    final url = Uri.parse(
      '${ApiConfig.mobileAppApiPath}search_items',
    ).replace(queryParameters: {
      'search_text': searchText,
      'customer_code': code, // ✅ AJOUTÉ — permet au backend de retourner le bon prix
    });

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      List rawItems = [];
      if (data is Map && data['message'] != null) {
        rawItems = data['message'] as List;
      } else if (data is List) {
        rawItems = data;
      }

      return rawItems
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      return [];
    } catch (e) {
      return [];
    }
  }

  // ── Order submission ────────────────────────────────────────────────────────

  Future<bool> submitOrder(List<Map<String, dynamic>> items) async {
    final code = Get.find<SessionService>().userCode;
    if (code.isEmpty) {
      throw const RepositoryException('Customer code not found in session');
    }
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}create_sales_order'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'customer_code': code, 'items': items}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      final decoded = json.decode(response.body);
      final msg     = decoded['message'];
      if (msg == null) throw const RepositoryException('Null message in response');
      return msg['status'] == 'success' || msg['order_id'] != null;
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  // ── Order history ───────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchOrders() async {
    final code = Get.find<SessionService>().userCode;
    if (code.isEmpty) {
      throw const RepositoryException('Customer code not found in session');
    }
    try {
      final url = Uri.parse('${_baseUrl}get_customer_orders')
          .replace(queryParameters: {'customer_code': code});

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      final data = json.decode(response.body);
      return (data['message']?['orders'] as List<dynamic>?) ?? [];
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<List<dynamic>?> getOrderItems(String orderId) async {
    try {
      final url = Uri.parse('${_baseUrl}get_order_details')
          .replace(queryParameters: {'order_id': orderId});

      final response =
          await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final msg  = data['message'];
        if (msg != null && msg['status'] == 'success') {
          return msg['items'] as List<dynamic>?;
        }
        return null;
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } on TimeoutException {
      throw const RepositoryException('Request timeout');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}