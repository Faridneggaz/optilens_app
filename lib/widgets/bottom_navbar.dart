import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../application/controllers/language_controller.dart';
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LanguageController>(
      builder: (_) => BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color.fromARGB(255, 247, 255, 253),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home),         label: 'nav_home'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.receipt_long), label: 'nav_invoices'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.payment),      label: 'nav_payments'.tr),
          BottomNavigationBarItem(icon: const Icon(Icons.person),       label: 'nav_profile'.tr),
        ],
      ),
    );
  }
}

