import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/user.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final user = repo.login(_email.text.trim(), _password.text.trim());
                if (user != null) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenciales inválidas')));
                }
              },
              child: const Text('Ingresar'),
            ),
            TextButton(
              onPressed: () async {
                // Crear usuario de prueba
                final messenger = ScaffoldMessenger.of(context);
                final id = const Uuid().v4();
                final user = User(id: id, email: _email.text.trim().isEmpty ? 'test@example.com' : _email.text.trim(), password: _password.text.trim().isEmpty ? 'password' : _password.text.trim(), name: 'Usuario de prueba');
                await repo.createUser(user);
                if (!mounted) return;
                messenger.showSnackBar(const SnackBar(content: Text('Usuario creado. Ahora presione Ingresar')));
              },
              child: const Text('Crear usuario (para pruebas)'),
            )
          ],
        ),
      ),
    );
  }
}

