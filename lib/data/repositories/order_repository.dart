import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/api_config.dart';
import 'repository_exception.dart';

class OrderRepository {
  final String _baseUrl = ApiConfig.mobileAppApiPath;

  Future<bool> submitOrder(List items) async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('custom_customer_code');
    if (code == null || code.isEmpty) {
      throw const RepositoryException('Customer code not found in preferences');
    }
    try {
      final response = await http.post(
        Uri.parse('${_baseUrl}create_sales_order'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'customer_code': code, 'items': items}),
      );
      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      final decoded = json.decode(response.body);
      final msg = decoded['message'];
      if (msg == null) throw const RepositoryException('Null message in response');
      return msg['status'] == 'success' || msg['order_id'] != null;
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<List> fetchOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('custom_customer_code');
    if (code == null || code.isEmpty) {
      throw const RepositoryException('Customer code not found in preferences');
    }
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}get_customer_orders?customer_code=$code'),
      );
      if (response.statusCode != 200) {
        throw RepositoryException('Server error: ${response.statusCode}');
      }
      final data = json.decode(response.body);
      return data['message']?['orders'] ?? [];
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }

  Future<List?> getOrderItems(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}get_order_details?order_id=$orderId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] != null && data['message']['status'] == 'success') {
          return data['message']['items'];
        }
        return null;
      }
      throw RepositoryException('Server error: ${response.statusCode}');
    } catch (e) {
      if (e is RepositoryException) rethrow;
      throw RepositoryException('Network error: $e');
    }
  }
}
