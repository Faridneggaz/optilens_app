import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/announcement.dart';

class AnnouncementController {
  
  final String baseUrl = "http://192.168.0.100:8000/api/method/mobile_app.api.get_announcements_by_customer_code";

  Future<List<Announcement>> fetchAnnouncements(String customerCode) async {
    try {
    
      final Uri url = Uri.parse("$baseUrl?code=$customerCode");
      
      print("Envoi requête Annonce: $url"); 

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = json.decode(response.body);
        
        
        if (responseJson.containsKey('message')) {
          final dynamic messageContent = responseJson['message'];

          if (messageContent is Map && messageContent.containsKey('announcements')) {
            List<dynamic> list = messageContent['announcements'];
            return list.map((item) => Announcement.fromJson(item)).toList();
          }
        }
      } else {
        print("Erreur Serveur: ${response.statusCode} - ${response.body}");
      }
      return [];
    } catch (e) {
      print("Erreur Exception: $e");
      return [];
    }
  }
}