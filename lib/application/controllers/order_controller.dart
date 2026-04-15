import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OrderController {
  // Utilisation de l'IP .107 comme dans votre fichier actuel
  final String baseUrl = "http://192.168.0.100:8000/api/method/mobile_app.api";

  Future<bool> submitOrder(List items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('custom_customer_code');

      if (code == null || code.isEmpty) return false;

      final response = await http.post(
        Uri.parse("$baseUrl.create_sales_order"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"customer_code": code, "items": items}),
      );

      if (response.statusCode != 200) return false;

      final decoded = json.decode(response.body);
      final msg = decoded['message'];
      if (msg == null) return false;

      return msg['status'] == 'success' || msg['order_id'] != null;
    } catch (e) {
      return false;
    }
  }

  Future<List> fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('custom_customer_code');
      if (code == null || code.isEmpty) return [];

      final response = await http.get(
        Uri.parse("$baseUrl.get_customer_orders?customer_code=$code"),
      );

      if (response.statusCode != 200) return [];
      final data = json.decode(response.body);
      return data['message']?['orders'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // --- NOUVELLE FONCTION POUR LES DÉTAILS ---
  Future<List?> getOrderItems(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl.get_order_details?order_id=$orderId"),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // On récupère les items dans le message de succès
        if (data['message'] != null && data['message']['status'] == 'success') {
          return data['message']['items'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}