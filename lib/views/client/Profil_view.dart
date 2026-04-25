import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../../application/controllers/session_controller.dart';
import '../../../app/routes/app_routes.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final SessionController _session = Get.find<SessionController>();

  @override
  Widget build(BuildContext context) {
    final customer = _session.customer.value!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 255, 253),
      body: Column(
        children: [
          AppHeader(
              title: '',
              customer: customer,
              customerCode: customer.code),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sectionTitle('Profile Information'),

                  Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          backgroundImage: NetworkImage(
                            'https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png',
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customer.name,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                customer.email ?? 'No email available',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle('Activités'),
                  _settingItem(
                    'Mes Commandes',
                    Icons.shopping_bag_outlined,
                    onTap: () => Get.toNamed(AppRoutes.orderHistory),
                  ),

                  _sectionTitle('Security Settings'),
                  _settingItem('Change Password', Icons.lock, onTap: () {}),

                  _sectionTitle('Notification Preferences'),
                  _settingItem('Manage Notifications', Icons.notifications,
                      onTap: () {}),

                  _sectionTitle('Support'),
                  _settingItem(
                    'Déposer une réclamation',
                    Icons.assignment_late_outlined,
                    onTap: () => Get.toNamed(AppRoutes.complaint),
                  ),

                  _settingItem('About Us', Icons.info_outline, onTap: () {}),
                  _settingItem('Help & Support', Icons.help_outline,
                      onTap: () {}),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 20, top: 25, bottom: 10),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87)),
    );
  }

  Widget _settingItem(String title, IconData icon,
      {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 26),
            const SizedBox(width: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}