// Login page using GetX AuthController
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'register_page.dart';
import '../../../home/ui/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.error.value != null) ...[
                  Text(controller.error.value!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  const SizedBox(height: 8),
                ],
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: controller.loading.value
                          ? null
                          : () async {
                              await controller.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
                              if (controller.currentUser.value != null) {
                                Get.offAll(() => const HomePage());
                              }
                            },
                      child: controller.loading.value
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Ingresar'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: controller.loading.value
                          ? null
                          : () => Get.to(() => const RegisterPage()),
                      child: const Text('Registrar usuario'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Login con GetX (estado reactivo).',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              ],
            )),
      ),
    );
  }
}
