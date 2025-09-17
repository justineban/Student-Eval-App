import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _showRegisterDialog() async {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registro de usuario'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su nombre' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su email' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Ingrese su contraseña' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                final user = await repo.register(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                  nameController.text.trim(),
                );
                if (user == null) {
                  messenger.showSnackBar(const SnackBar(content: Text('Email ya registrado')));
                  return;
                }
                await repo.persistSession(user);
                if (!mounted) return;
                navigator.pushReplacementNamed('/home');
              },
              child: const Text('Registrar'),
            ),
          ],
        );
      },
    );
  }
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
              onPressed: _showRegisterDialog,
              child: const Text('Registrar usuario'),
            )
          ],
        ),
      ),
    );
  }
}

