import 'package:flutter/material.dart';

import '../../../../shared/layout/main_layout.dart';
import '../widgets/dashboard_body.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainLayout(
      title: "Dashboard",
      child: DashboardBody(),
    );
  }
}