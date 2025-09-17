import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/local_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final user = await repo.register(_email.text.trim(), _password.text.trim(), _name.text.trim());
                if (user == null) {
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('Email ya registrado')));
                  return;
                }
                await repo.persistSession(user);
                if (!mounted) return;
                navigator.pushReplacementNamed('/roles');
              },
              child: const Text('Registrar'),
            )
          ],
        ),
      ),
    );
  }
}
