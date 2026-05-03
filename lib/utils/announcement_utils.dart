import 'package:flutter/material.dart';
import '../domain/response/announcement.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;

  const AnnouncementCard({super.key, required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool hasImage = announcement.image != null && announcement.image!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER : Image ou Icône
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                announcement.image!,
                height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (context, e, s) => _buildIconPlaceholder(),
              ),
            )
          else
            _buildIconPlaceholder(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge(),
                const SizedBox(height: 8),
                Text(announcement.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(announcement.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Posté le ${announcement.postedTime}", style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A89C), foregroundColor: Colors.white),
                      child: const Text("Voir plus"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget _buildIconPlaceholder() {
  return Container(
    height: 100, 
    width: double.infinity,
    decoration: BoxDecoration(

      color: announcement.colorValue.withValues(alpha: 0.1), 
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Icon(
      Icons.campaign_outlined, 
      size: 40, 
  
      color: announcement.colorValue, 
    ),
  );
}

 

  Widget _buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: announcement.colorValue, 
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        announcement.type.toUpperCase(), 
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}