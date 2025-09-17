import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/local_repository.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String roleName;
  final String? title;

  const TopBar({super.key, required this.roleName, this.title});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    return AppBar(
      title: Text(title ?? ''),
      actions: [
        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text('Rol: $roleName'))),
        IconButton(
          tooltip: 'Cambiar rol',
          icon: const Icon(Icons.swap_horiz),
          onPressed: () => Navigator.pushNamed(context, '/roles'),
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
