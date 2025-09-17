import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/local_repository.dart';


class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;

  const TopBar({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context, listen: false);
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
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: const Icon(Icons.logout),
          onPressed: () async {
            final navigator = Navigator.of(context);
            await repo.logout();
            navigator.pushReplacementNamed('/login');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
