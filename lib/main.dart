import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/utils/local_repository.dart';
import 'core/entities/course.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';git log --oneline -n 3
import 'features/home/presentation/home_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';

Future<void> _initTestUsersAndCourses() async {
  final localRepo = LocalRepository.instance;

  // Evitar volver a sembrar si ya se hizo antes
  if (localRepo.sessionBox.get('seed_done') == true) {
    debugPrint('Seed ya realizado, se omite.');
    return;
  }

  // Si ya existe un curso seed (por id fijo) también salir
  const seedCourseId = 'seed_curso1';
  final existingSeed = localRepo.coursesBox.get(seedCourseId);
  if (existingSeed != null) {
    localRepo.sessionBox.put('seed_done', true);
    debugPrint('Curso seed ya presente.');
    return;
  }

  // Usuarios que estarán inscritos a curso1
  final emailsCurso1 = [
    'a@a.com',
    'b@a.com',
    'c@a.com',
    'd@a.com',
    'e@a.com',
    'f@a.com',
    'g@a.com',
  ];
  // Usuarios que NO estarán inscritos a ningún curso
  final emailsSinCurso = [
    'a@b.com',
    'b@b.com',
    'c@b.com',
    'd@b.com',
    'e@b.com',
    'f@b.com',
    'g@b.com',
  ];

  // Crear usuarios (idempotente gracias a register que valida email)
  for (final email in [...emailsCurso1, ...emailsSinCurso]) {
    try {
      await localRepo.register(email, '12345', 'Usuario Prueba');
    } catch (_) {
      // Ignorar si ya existe
    }
  }

  // Profesor del curso seed
  final teacher = localRepo.users.firstWhere((u) => u.email == 'a@a.com');

  // Crear curso seed con ID estable para no duplicar en reinicios
  final curso1 = Course(
    id: seedCourseId,
    name: 'curso1',
    description: 'Curso de prueba',
    teacherId: teacher.id,
    // Código estático
    registrationCode: 'CURS01',
  );

  // Añadir estudiantes (menos el profesor)
  for (final email in emailsCurso1.where((e) => e != 'a@a.com')) {
    final user = localRepo.users.firstWhere((u) => u.email == email);
    if (!curso1.studentIds.contains(user.id)) {
      curso1.studentIds.add(user.id);
    }
  }

  // Persistir una sola vez
  await localRepo.createCourse(curso1);
  localRepo.sessionBox.put('seed_done', true);
  debugPrint('Seed: curso1 creado (ID fijo $seedCourseId).');

  // Limpieza de duplicados antiguos (cursos con mismo nombre 'curso1' y distinto id)
  final duplicates = localRepo.coursesBox.values
      .where((c) => c.name == 'curso1' && c.id != seedCourseId)
      .toList();
  if (duplicates.isNotEmpty) {
    for (final d in duplicates) {
      await localRepo.deleteCourse(d.id);
      debugPrint('Eliminado curso duplicado antiguo: ${d.id}');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalRepository.registerAdapters();
  await LocalRepository.openBoxes();
  await _initTestUsersAndCourses();
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
        home: LocalRepository.instance.currentUser == null
            ? const LoginScreen()
            : const HomeScreen(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
          '/groups': (context) {
            final categoryId =
                ModalRoute.of(context)!.settings.arguments as String;
            return GroupsListScreen(categoryId: categoryId);
          },
        },
      ),
    );
  }
}
