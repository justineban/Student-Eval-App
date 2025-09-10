import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository_impl.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthRepositoryImpl().currentUser;

    final role = AuthRepositoryImpl().currentRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthRepositoryImpl().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null)
              Text(
                'Bienvenido, ${user.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rol: ${role ?? "no seleccionado"}'),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/select-role'),
                  child: const Text('Cambiar Rol'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.school,
                    label: AuthRepositoryImpl().currentRole == 'student'
                        ? 'Join a Course'
                        : 'Cursos',
                    onTap: () => Navigator.pushNamed(
                      context,
                      AuthRepositoryImpl().currentRole == 'student'
                          ? '/join-course'
                          : '/courses',
                    ),
                  ),
                  _ActionCard(
                    icon: Icons.list_alt,
                    label: 'Categorías',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/select-course-for-categories',
                    ),
                  ),
                  if (AuthRepositoryImpl().currentRole == 'teacher')
                    _ActionCard(
                      icon: Icons.group,
                      label: 'Usuarios',
                      onTap: () => Navigator.pushNamed(context, '/users'),
                    ),
                  if (AuthRepositoryImpl().currentRole == 'teacher')
                    _ActionCard(
                      icon: Icons.list,
                      label: 'Todos los Grupos',
                      onTap: () => Navigator.pushNamed(context, '/all-groups'),
                    ),
                  if (AuthRepositoryImpl().currentRole == 'student')
                    _ActionCard(
                      icon: Icons.bookmark_added,
                      label: 'Mis Inscripciones',
                      onTap: () => Navigator.pushNamed(context, '/enrolled'),
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
