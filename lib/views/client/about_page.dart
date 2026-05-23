import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 253),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 167, 155),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: Text(
          'about'.tr,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            Image.asset(
              'assets/images/optilensss.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Optilens',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 167, 155),
              ),
            ),
            
            const SizedBox(height: 6),
            
            const Text(
              'v1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 40),
            
            _buildInfoCard(
              icon: Icons.business,
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
              value: '+213 XX XX XX XX',
            ),
            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: 'address'.tr,
              value: 'Algiers, Algeria',
            ),
            
            const SizedBox(height: 40),
            
            const Text(
              '© 2025 Optilens. All rights reserved.',
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
        color: const Color.fromARGB(255, 235, 248, 246),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 0, 167, 155)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
