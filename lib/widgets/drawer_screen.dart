import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int) onSelectPage;
  final bool isUser;

  const DrawerScreen({super.key, required this.onSelectPage, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
              child: Image.asset('assets/images/optilensss.png', height: 100),
            ),
            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.home, color: Color(0xFF3BADA2)),
                    title: const Text("Home"),
                    onTap: () {
                      onSelectPage(0); // Dashboard vide pour User, Home pour Client
                      ZoomDrawer.of(context)?.close();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: Color(0xFF3BADA2)),
                    title: const Text("Notifications"),
                    onTap: () {
                      onSelectPage(1); // Page notifications pour les deux
                      ZoomDrawer.of(context)?.close();
                    },
                  ),
                  if (isUser) // Option Stock uniquement pour l'employé
                    ListTile(
                      leading: const Icon(Icons.inventory_2, color: Color(0xFF3BADA2)),
                      title: const Text("Stock "),
                      onTap: () {
                        onSelectPage(2); // Page de stock dédiée
                        ZoomDrawer.of(context)?.close();
                      },
                    ),
                ],
              ),
            ),
                    Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 30, right: 12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'POWERED BY JETHINGS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                      color: Color.fromARGB(255, 42, 96, 96),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}