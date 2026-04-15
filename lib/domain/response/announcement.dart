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

  // METS TON IP ICI (Celle de ton serveur ERPNext)
  static const String baseUrl = "http://192.168.0.100:8000";

  factory Announcement.fromJson(Map<String, dynamic> json) {
    String? rawImage = json['image'] ?? json['banner_image']; // Gère les deux noms
    
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