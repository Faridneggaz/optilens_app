import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int) onSelectPage;

  const DrawerScreen({super.key, required this.onSelectPage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 254, 255, 255),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 15),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/optilensss.png',
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.home,
                      color: Color.fromARGB(255, 59, 173, 162),
                    ),
                    title: const Text(
                      "Home",
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                    onTap: () {
                      onSelectPage(0);
                      ZoomDrawer.of(context)?.close();
                    },
                  ),

                  ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Color.fromARGB(255, 59, 173, 162),
                    ),
                    title: const Text(
                      "Notifications",
                      style: TextStyle(color: Colors.black45, fontSize: 16),
                    ),
                    onTap: () {
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
