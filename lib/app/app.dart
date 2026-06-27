import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'app_router.dart';

class ProyectoMaxApp extends StatelessWidget {
  const ProyectoMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Proyecto MAX ERP',

      theme: AppTheme.lightTheme,

      routerConfig: appRouter,
    );
  }
}