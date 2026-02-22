import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String postedTime;
  final bool isNew;
  final Color themeColor; // Nouveau champ pour la couleur dynamique

  const AnnouncementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.postedTime,
    this.isNew = false,
    this.themeColor = const Color.fromRGBO(0, 169, 157, 1), // Vert par défaut
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), // Un peu plus d'espace vertical
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fond très pâle basé sur la couleur du thème (opacité 10%)
        color: themeColor.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // Bordure pâle basée sur la couleur du thème (opacité 30%)
          color: themeColor.withOpacity(0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // L'icône prend la couleur forte
              Icon(icon, color: themeColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color.fromRGBO(31, 40, 55, 1),
                  ),
                ),
              ),
              if (isNew)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "NEW",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                postedTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ],
      ),
    );
  }
}