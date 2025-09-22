import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'core/di/app_bindings.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';

// TODO: Migrar generación de datos de prueba a un seed script / fixture separado si aún se requiere.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Apertura de boxes Hive debería estar centralizada antes de runApp si no se hace en bindings.
  // (Asumimos que AppBindings usará Hive.box ya abierto; abrir aquí si falta.)
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Student Eval App',
      initialBinding: AppBindings(),
      theme: ThemeData(primarySwatch: Colors.blue),
      getPages: [
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/groups', page: () {
          final categoryId = Get.arguments as String;
          return GroupsListScreen(categoryId: categoryId);
        }),
      ],
      initialRoute: '/login',
      onInit: () {
        // Punto para cargar sesión persistida si se implementa.
        // Get.find<AuthController>().restoreSessionIfAny(); (método futuro)
      },
    );
  }
}
