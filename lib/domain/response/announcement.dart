class Announcement {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String priority;
  final String icon;
  final String color;
  final String postedTime;
  final bool isNew;
  final String? image;
  final String? actionLabel;
  final String? actionRoute;

  Announcement({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.priority,
    required this.icon,
    required this.color,
    required this.postedTime,
    required this.isNew,
    this.image,
    this.actionLabel,
    this.actionRoute,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? "",
      title: json['title'] ?? "",
      subtitle: json['subtitle'] ?? "",
      type: json['type'] ?? "Information",
      priority: json['priority'] ?? "Medium",
      icon: json['icon'] ?? "campaign",
      color: json['color'] ?? "#00A89C",
      postedTime: json['postedTime'] ?? "",
      isNew: json['isNew'] == 1,
      image: json['image'],
      actionLabel: json['actionLabel'],
      actionRoute: json['actionRoute'],
    );
  }
}