import 'package:flutter/material.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'presentation/pages/courses/course_list_screen.dart';
import 'presentation/pages/courses/enrolled_courses_screen.dart';
import 'presentation/pages/home/home_screen.dart';
import 'presentation/pages/users/users_list_screen.dart';
import 'presentation/pages/category/category_picker_screen.dart';
import 'presentation/pages/auth/role_selection_screen.dart';
import 'presentation/pages/category/all_groups_screen.dart';
import 'presentation/pages/courses/join_course_screen.dart';
import 'data/repositories/auth_repository_impl.dart';

<<<<<<< Updated upstream
void main() {
=======
import 'features/home/presentation/home_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';
import 'core/entities/course.dart';

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
    // Código estático o derivado; podría regenerarse si quieres
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalRepository.registerAdapters();
  await LocalRepository.openBoxes();
  // Crear usuarios y curso de prueba si no existen
  await _initTestUsersAndCourses();
  // load any persisted session
  LocalRepository.instance.loadCurrentUserFromSession();
>>>>>>> Stashed changes
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return MaterialApp(
      title: 'Gestión de Cursos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
=======
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
>>>>>>> Stashed changes
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthRepositoryImpl().currentUser == null
            ? const LoginScreen()
            : const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/select-course-for-categories': (context) =>
            const CategoryPickerScreen(),
        '/select-role': (context) => const RoleSelectionScreen(),
        '/all-groups': (context) => const AllGroupsScreen(),
        '/join-course': (context) => const JoinCourseScreen(),
        '/courses': (context) => const CourseListScreen(),
        '/enrolled': (context) => const EnrolledCoursesScreen(), // Ruta añadida
        '/users': (context) => const UsersListScreen(),
      },
    );
  }
}
