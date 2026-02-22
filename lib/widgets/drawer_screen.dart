import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int) onSelectPage;
  final VoidCallback onLogout; // Nécessaire pour la déconnexion
  final bool isUser;

  const DrawerScreen({
    super.key,
    required this.onSelectPage,
    required this.isUser,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            // --- LOGO ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
              child: Image.asset('assets/images/optilensss.png', height: 100),
            ),
            
            // --- MENU ITEMS ---
            Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home, color: Color(0xFF3BADA2)),
                  title: const Text("Home"),
                  onTap: () {
                    onSelectPage(0);
                    ZoomDrawer.of(context)?.close();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xFF3BADA2)),
                  title: const Text("Notifications"),
                  onTap: () {
                    onSelectPage(1);
                    ZoomDrawer.of(context)?.close();
                  },
                ),
                if (isUser)
                  ListTile(
                    leading: const Icon(Icons.inventory_2, color: Color(0xFF3BADA2)),
                    title: const Text("Stock"),
                    onTap: () {
                      onSelectPage(2);
                      ZoomDrawer.of(context)?.close();
                    },
                  ),
              ],
            ),

            const Spacer(), // Pousse le contenu suivant tout en bas

            // --- BOUTON LOGOUT (Même design que Profile) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  ZoomDrawer.of(context)?.close();
                  onLogout();
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.logout,
                        color: Color.fromARGB(255, 223, 54, 38),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Log Out",
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

            // --- FOOTER POWERED BY (Même design que Profile) ---
            Text.rich(
              const TextSpan(
                text: "Powered by ",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16, // Légèrement réduit pour s'adapter au drawer
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: "Jethings",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30), // Espace en bas
          ],
        ),
      ),
    );
  }
}