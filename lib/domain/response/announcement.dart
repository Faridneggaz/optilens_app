import 'package:flutter/material.dart';
import '../../utils/api_config.dart';

class Announcement {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String priority;
  final String color; 
  final String postedTime;
  final String? image;

  Announcement({
    required this.id, required this.title, required this.subtitle,
    required this.type, required this.priority, required this.color,
    required this.postedTime, this.image,
  });


  static const String baseUrl = ApiConfig.baseUrl;

  Color get colorValue {
    try {
      String hexColor = color.replaceAll("#", "");
      if (hexColor.length == 6) hexColor = "FF$hexColor"; 
      return Color(int.parse("0x$hexColor"));
    } catch (e) {
      return const Color(0xFF00A89C);
    }
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['image'] ?? json['banner_image'];
    
    String? fullImageUrl;
    if (rawImage != null && rawImage.isNotEmpty) {

      fullImageUrl = rawImage.startsWith('http') ? rawImage : "$baseUrl$rawImage";
    }

    return Announcement(
      id: json['id'] ?? json['name'] ?? "",
      title: json['title'] ?? "",
      subtitle: json['subtitle'] ?? json['description'] ?? "",
      type: json['type'] ?? json['announcement_typ'] ?? "Info",
      priority: json['priority'] ?? "Medium",
      color: json['color'] ?? "#00A89C",
      postedTime: json['postedTime'] ?? json['publish_date'] ?? "",
      image: fullImageUrl,
    );
  }
}