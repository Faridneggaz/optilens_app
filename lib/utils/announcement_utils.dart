import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String postedTime;
  final bool isNew;
  final Color themeColor;
  final String? imageUrl;
  final String priority;
  final String type; // Promotion, New Arrival, Maintenance, etc.
  final String? actionLabel;

  const AnnouncementCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.postedTime,
    this.isNew = false,
    this.themeColor = const Color.fromRGBO(0, 169, 157, 1),
    this.imageUrl,
    this.priority = "Medium",
    this.type = "Info",
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    // On choisit le layout en fonction du type ou de la présence d'une image
    if (type.toLowerCase() == 'promotion' || type.toLowerCase() == 'promo') {
      return _buildLargePromoCard();
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      return _buildCompactImageCard();
    } else {
      return _buildIconCard();
    }
  }

  // --- 1. GRANDE CARTE (PROMOTION) ---
  Widget _buildLargePromoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _buildBadge(type.toUpperCase(), Colors.redAccent),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle()),
                const SizedBox(height: 6),
                Text(subtitle, style: _subtitleStyle(), maxLines: 2),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(postedTime, style: _dateStyle()),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text(actionLabel ?? "Claim Offer"),
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

  // --- 2. CARTE COMPACTE (IMAGE À GAUCHE) ---
  Widget _buildCompactImageCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBadge(type.toUpperCase(), Colors.teal.shade300),
                const SizedBox(height: 8),
                Text(title, style: _titleStyle(fontSize: 15)),
                Text(subtitle, style: _subtitleStyle(fontSize: 12), maxLines: 2),
                const SizedBox(height: 4),
                Text(postedTime, style: _dateStyle()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. CARTE INFO (ICÔNE À GAUCHE) ---
  Widget _buildIconCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBadge(type.toUpperCase(), Colors.grey.shade400),
                    Text(postedTime, style: _dateStyle()),
                  ],
                ),
                const SizedBox(height: 4),
                Text(title, style: _titleStyle(fontSize: 15)),
                Text(subtitle, style: _subtitleStyle(fontSize: 12), maxLines: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS DE STYLE ---
  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
  );

  Widget _buildBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
  );

  TextStyle _titleStyle({double fontSize = 17}) => TextStyle(
    fontWeight: FontWeight.bold, fontSize: fontSize, color: const Color(0xFF1F2837),
  );

  TextStyle _subtitleStyle({double fontSize = 14}) => TextStyle(
    color: Colors.grey.shade600, fontSize: fontSize, height: 1.3,
  );

  TextStyle _dateStyle() => TextStyle(fontSize: 11, color: Colors.grey.shade400);
}