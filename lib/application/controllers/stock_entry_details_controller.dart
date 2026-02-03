import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/stock_entry_details_response.dart';

class StockEntryDetailsController {
  static const String baseUrl = "http://192.168.100.20:8000/api/method/";
  
  static const String fetchEndpoint = "mobile_app.api.get_stock_entry_details_by_name";
  static const String manageEndpoint = "mobile_app.api.manage_stock_entry";
  static const String searchEndpoint = "mobile_app.api.search_items";

  Future<StockEntryDetailsResponse?> fetchDetails({
    required String name,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl$fetchEndpoint?name=$name&token=$token");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded["error"] != null) return null;
        return StockEntryDetailsResponse.fromJson(decoded);
      }
    } catch (e) {
      print("Erreur fetchDetails: $e");
    }
    return null;
  }

  Future<bool> manageStockEntry({
    required String token,
    required String name,
    required String items,
    required String action,
  }) async {
    final url = Uri.parse("$baseUrl$manageEndpoint");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "token": token,
          "name": name,
          "items": items,
          "action": action,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return result["message"] == "Success";
      }
    } catch (e) {
      print("Erreur manageStockEntry: $e");
    }
    return false;
  }

  // ✅ MÉTHODE CORRIGÉE avec POST JSON (comme InvoiceDetailController)
  Future<Map<String, dynamic>> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    try {
      final url = Uri.parse("$baseUrl$manageEndpoint");
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'items': items,  // ✅ Directement la liste, pas json.encode()
          'action': action,
        }),
      );

      print('Status Code: ${response.statusCode}'); // Debug
      print('Response Body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ Frappe renvoie dans 'message'
        if (data['message'] != null) {
          final result = data['message'];
          
          if (result is Map && result["message"] == "Success") {
            return {
              "message": "Success",
              "detail": result["detail"] ?? "Operation completed"
            };
          } else if (result is Map && result["error"] != null) {
            return {"error": result["error"]};
          }
        }
        
        // Si pas de 'message', vérifier directement
        if (data["message"] == "Success") {
          return {"message": "Success", "detail": data["detail"] ?? ""};
        }
        if (data["error"] != null) {
          return {"error": data["error"]};
        }
      }
      
      return {"error": "Server error: ${response.statusCode}"};
      
    } catch (e) {
      print("Erreur approveStockEntry: $e");
      return {"error": "Network error: $e"};
    }
  }

  Future<List<Map<String, String>>> searchItems({
    required String token,
    required String searchText,
  }) async {
    final url = Uri.parse("$baseUrl$searchEndpoint?token=$token&search_text=$searchText");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          return decoded.map<Map<String, String>>((e) => {
            "item_code": e["item_code"] ?? "",
            "item_name": e["item_name"] ?? ""
          }).toList();
        }
      }
    } catch (e) {
      print("Erreur searchItems: $e");
    }
    return [];
  }
}