import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyecto_movil/features/auth/presentation/controllers/auth_controller.dart';


class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const TopBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
  final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    return AppBar(
      // Default leading (back button) is restored by not specifying leading
      title: Text(title ?? ''),
      actions: [
        IconButton(
          tooltip: 'Inicio',
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          },
        ),
        if (auth != null && auth.isLoggedIn)
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logoutUser();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
