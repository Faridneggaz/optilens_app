import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

class NotificationRepository {
  static const String _baseUrl = ApiConfig.apiMethodPath;

  Future<List<dynamic>> fetchNotifications(String customerCode) async {
    final url = Uri.parse(
      '$_baseUrl'
      'mobile_app.api.get_notification_by_customer_code'
      '?code=${Uri.encodeComponent(customerCode)}'
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body    = jsonDecode(response.body);
        final message = body['message'];
        if (message == null) return [];
        final list = message['notification'];
        if (list == null) return [];
        return List<dynamic>.from(list);
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
