import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/stock_entry_details_response.dart';

class StockEntryDetailsController {
  static const String baseUrl = "https://optilens.jethings.com/api/method/";
  static const String endpoint =
      "mobile_app.api.get_stock_entry_details_by_name";

  Future<StockEntryDetailsResponse?> fetchDetails({
    required String name,
    required String token,
  }) async {
    final url = Uri.parse("$baseUrl$endpoint?name=$name&token=$token");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return StockEntryDetailsResponse.fromJson(jsonData);
      } else {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
