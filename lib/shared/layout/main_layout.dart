import 'package:flutter/material.dart';

import '../widgets/navigation/side_menu.dart';
import '../widgets/navigation/top_bar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const MainLayout({
    super.key,
    required this.child,
    this.title = "Dashboard",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      body: SafeArea(
        child: Row(
          children: [

            // =============================
            // Menú lateral
            // =============================

            const SideMenu(),

            // =============================
            // Contenido
            // =============================

            Expanded(
              child: Column(
                children: [

                  TopBar(
                    title: title,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}