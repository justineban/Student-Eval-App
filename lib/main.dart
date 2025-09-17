import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/utils/local_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';

import 'features/home/presentation/home_screen.dart';
import 'features/groups/presentation/groups_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await LocalRepository.registerAdapters();
  await LocalRepository.openBoxes();
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
