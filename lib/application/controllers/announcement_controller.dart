import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/response/announcement.dart';

class AnnouncementController {
  final String baseUrl = "http://192.168.100.20:8000/api/method/mobile_app.api.get_announcements";

  Future<List<Announcement>> fetchAnnouncements(String userId) async {
    try {
    
      final Uri url = Uri.parse("$baseUrl?user=$userId");
      
      print("🚀 Envoi requête Annonce: $url"); 

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data.containsKey('data')) {
          List<dynamic> list = data['data'];
          return list.map((item) => Announcement.fromJson(item)).toList();
        }
      } else {
        print("❌ Erreur Serveur: ${response.statusCode}");
      }
      return [];
    } catch (e) {
      print("❌ Erreur Exception: $e");
      return [];
    }
  }
}