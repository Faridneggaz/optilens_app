import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:get/get.dart';
import '../application/controllers/session_controller.dart';

/// The slide-out drawer. Removed onLogout callback — uses SessionController
/// directly. Removed onSelectPage callback — caller passes it in (ZoomDrawerPage).
class DrawerScreen extends StatelessWidget {
  final Function(int) onSelectPage;
  final bool isUser;

  const DrawerScreen({
    super.key,
    required this.onSelectPage,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
              child:
                  Image.asset('assets/images/optilensss.png', height: 100),
            ),

            // Menu items
            Column(children: [
              ListTile(
                leading: const Icon(Icons.home, color: Color(0xFF3BADA2)),
                title: const Text('Home'),
                onTap: () => onSelectPage(0),
              ),
              ListTile(
                leading: const Icon(Icons.notifications,
                    color: Color(0xFF3BADA2)),
                title: const Text('Notifications'),
                onTap: () => onSelectPage(1),
              ),
              if (isUser)
                ListTile(
                  leading: const Icon(Icons.inventory_2,
                      color: Color(0xFF3BADA2)),
                  title: const Text('Stock'),
                  onTap: () => onSelectPage(2),
                ),
            ]),

            const Spacer(),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  ZoomDrawer.of(context)?.close();
                  Get.find<SessionController>().logout();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 226, 227),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.logout,
                          color: Color.fromARGB(255, 223, 54, 38)),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          color: Color.fromARGB(255, 223, 54, 38),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Footer
            Text.rich(
              const TextSpan(
                text: 'Powered by ',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: 'Jethings',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}