import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/header.dart';
import '../../../presentation/controllers/language_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../widgets/client_session_gate.dart';
import '../../core/theme/app_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ClientSessionGate(
      builder: (customer) => GetBuilder<LanguageController>(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.scaffold,
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
                    _sectionTitle('profile_info'.tr),

                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(10),
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
                                  customer.email ?? 'no_email'.tr,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    _sectionTitle('activities'.tr),
                    _settingItem(
                      'my_orders'.tr,
                      Icons.shopping_bag_outlined,
                      onTap: () => Get.toNamed(AppRoutes.orderHistory),
                    ),

                    _sectionTitle('security'.tr),
                    _settingItem('change_password'.tr, Icons.lock,
                        onTap: () => Get.toNamed(AppRoutes.changePassword)),

                    _sectionTitle('support'.tr),
                    _settingItem(
                      'submit_complaint'.tr,
                      Icons.assignment_late_outlined,
                      onTap: () => Get.toNamed(AppRoutes.complaint),
                    ),

                    _settingItem('about'.tr, Icons.info_outline,
                        onTap: () => Get.toNamed(AppRoutes.about)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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