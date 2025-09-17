import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/utils/local_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';
import 'features/auth/data/auth_service.dart';
import 'core/entities/course.dart';

Future<void> _initTestUsersAndCourses() async {
  final localRepo = LocalRepository.instance;
  // Usuarios que estarán inscritos a curso1
  final emailsCurso1 = [
    'a@a.com', 'b@a.com', 'c@a.com', 'd@a.com', 'e@a.com', 'f@a.com', 'g@a.com'
  ];
  // Usuarios que NO estarán inscritos a ningún curso
  final emailsSinCurso = [
    'a@b.com', 'b@b.com', 'c@b.com', 'd@b.com', 'e@b.com', 'f@b.com', 'g@b.com'
  ];
  // Crear todos los usuarios usando el register de LocalRepository
  for (final email in [...emailsCurso1, ...emailsSinCurso]) {
    try {
      await localRepo.register(email, '12345', 'Usuario Prueba');
      debugPrint('Usuario $email creado');
    } catch (_) {}
  }
  // Crear curso1 con a@a.com como profesor
  final teacher = localRepo.users.firstWhere((u) => u.email == 'a@a.com');
  localRepo.currentUser = teacher;
  // Sincronizar también el usuario conectado en AuthService
  AuthService().currentUser = teacher;
  try {
    final curso1 = Course(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'curso1',
      description: 'Curso de prueba',
      teacherId: teacher.id,
      registrationCode: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    await localRepo.createCourse(curso1);
    debugPrint('Curso1 creado con ID: ${curso1.id} y código: ${curso1.registrationCode}');
    // Inscribir los usuarios (excepto el profesor) al curso1
    for (final email in emailsCurso1.where((e) => e != 'a@a.com')) {
      final user = localRepo.users.firstWhere((u) => u.email == email);
      if (!curso1.studentIds.contains(user.id)) {
        curso1.studentIds.add(user.id);
        debugPrint('Usuario $email inscrito al curso1');
      }
    }
    // Guardar cambios de estudiantes inscritos
    await localRepo.createCourse(curso1);
    // Restaurar currentUser a null en ambos servicios
    localRepo.currentUser = null;
    AuthService().currentUser = null;
  } catch (e) {
    debugPrint('Error al crear curso1: $e');
    return;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalRepository.registerAdapters();
  await LocalRepository.openBoxes();
  // Crear usuarios y curso de prueba si no existen
  await _initTestUsersAndCourses();
  // load any persisted session
  LocalRepository.instance.loadCurrentUserFromSession();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocalRepository.instance),
      ],
      child: MaterialApp(
        title: 'Student Eval App',
        theme: ThemeData(primarySwatch: Colors.blue),
  home: LocalRepository.instance.currentUser == null ? const LoginScreen() : const HomeScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/groups': (context) {
            final categoryId = ModalRoute.of(context)!.settings.arguments as String;
            return GroupsListScreen(categoryId: categoryId);
          },
        },
      ),
    );
  }
}
