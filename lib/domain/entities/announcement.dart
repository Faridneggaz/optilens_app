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
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.priority,
    required this.color,
    required this.postedTime,
    this.image,
  });
}
