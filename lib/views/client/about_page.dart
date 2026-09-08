import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _teal = Color(0xFF00A79B);
  static const Color _darkBlue = Color(0xFF1F2837);
  static const Color _bg = Color(0xFFF7FFFD);
  static const Color _cardColor = Color(0xFFEBF8F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: const BackButton(color: _teal),
        title: Text(
          'about'.tr,
          style: const TextStyle(color: _darkBlue, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            Center(
              child: Image.asset(
                'assets/images/optilensss.png',
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 32),
            
            _buildInfoCard(
              icon: Icons.business_rounded,
              title: 'company'.tr,
              value: 'Optilens Algeria',
            ),
            _buildInfoCard(
              icon: Icons.email_outlined,
              title: 'contact'.tr,
              value: 'contact@optilens.dz',
            ),
            _buildInfoCard(
              icon: Icons.phone_outlined,
              title: 'phone'.tr,
              value: '+213 797 39 46 85',
            ),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: 'address'.tr,
              value: 'Algiers, Algeria',
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              '© 2026 Optilens. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _darkBlue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}