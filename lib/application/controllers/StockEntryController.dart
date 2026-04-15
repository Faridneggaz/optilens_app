import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/StockEntryResponse.dart';

class StockEntryController {
  static const String baseUrl = "http://192.168.0.104:8000/api/method/";
  static const String getLastStockEntries = "mobile_app.api.get_last_stock_entries";

  Future<StockEntryResponse?> fetchLastStockEntries({
    required String token,
    int limit = 20,
    int offset = 0 
  }) async {
    final url = Uri.parse(
      "$baseUrl$getLastStockEntries?token=$token&limit=$limit&offset=$offset",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return StockEntryResponse.fromJson(jsonData);
      } else {
        print("Erreur serveur: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Erreur réseau: $e");
      return null;
    }
  }
}