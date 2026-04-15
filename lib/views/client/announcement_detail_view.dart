import 'package:flutter/material.dart';
import '../../domain/response/announcement.dart';

class AnnouncementDetailPage extends StatelessWidget {
  final Announcement announcement;

  const AnnouncementDetailPage({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Détails de l'annonce"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2837),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Affichage de l'image en haut si elle existe
            if (announcement.image != null && announcement.image!.isNotEmpty)
              Image.network(
                announcement.image!,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type d'annonce (Badge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECA04B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      announcement.type.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Titre
                  Text(
                    announcement.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1F2837)),
                  ),
                  const SizedBox(height: 8),
                  
                  // Date de publication
                  Text(
                    "Publié le ${announcement.postedTime}",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const Divider(height: 40, thickness: 1),
                  
                  // Description COMPLÈTE
                  Text(
                    announcement.subtitle, 
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}