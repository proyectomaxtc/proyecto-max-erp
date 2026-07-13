import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/layout/main_layout.dart';
import '../../../shared/widgets/access_denied_page.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/dashboard_body.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esPropietario = ref.watch(authProvider).esPropietario;

    if (!esPropietario) {
      return const AccessDeniedPage(
        title: "Dashboard",
        message: "El dashboard administrativo es solo para propietarios.",
      );
    }

    return const MainLayout(
      title: "Dashboard",
      child: DashboardBody(),
    );
  }
}
