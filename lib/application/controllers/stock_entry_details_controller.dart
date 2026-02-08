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

  // ✅ SOLUTION FINALE: Token dans le body ET dans l'URL
  Future<Map<String, dynamic>> approveStockEntry({
    required String name,
    required String token,
    required List<Map<String, dynamic>> items,
    required String action,
  }) async {
    try {
      // ✅ Garder le token dans l'URL aussi (au cas où)
      final url = Uri.parse("$baseUrl$manageEndpoint?token=$token");
      
      print('=== DEBUG APPROVE REQUEST ===');
      print('URL: $url');
      print('Token length: ${token.length}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'items': items,
          'action': action,
          'token': token, // ✅ IMPORTANT: Token aussi dans le body
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Frappe encapsule souvent la réponse dans 'message'
        var resData = data['message'] ?? data;

        if (resData["message"] == "Success") {
          return {
            "message": "Success",
            "detail": resData["detail"] ?? "Operation completed successfully"
          };
        } else if (resData["error"] != null) {
          return {"error": resData["error"]};
        }
        
        return {"error": "Unknown response format"};
      } else {
        return {"error": "Server error: ${response.statusCode} - ${response.body}"};
      }
      
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
        
        List itemsList;
        if (decoded is Map && decoded['message'] != null) {
          itemsList = decoded['message'] as List;
        } else if (decoded is List) {
          itemsList = decoded;
        } else {
          return [];
        }
        
        return itemsList.map<Map<String, String>>((e) => {
          "item_code": e["item_code"]?.toString() ?? "",
          "item_name": e["item_name"]?.toString() ?? ""
        }).toList();
      }
    } catch (e) {
      print("Erreur searchItems: $e");
    }
    return [];
  }
}