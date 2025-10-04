import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/auth/ui/controllers/auth_controller.dart';
import '../../features/auth/ui/pages/login_page.dart';
import '../../features/home/ui/pages/home_page.dart';

/// SplashPage decides the initial route based on auth state without flashing
/// unintended screens. It observes AuthController and redirects to Home or Login.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    // React to changes in loading/user; when loading completes, navigate.
    ever<bool>(_auth.loading, (_) => _maybeNavigate());
    ever<_UserWrap>(_UserWrapRx(_auth.currentUser), (_) => _maybeNavigate());
    // Also attempt immediate navigation in case restore already finished.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());
  }

  void _maybeNavigate() {
    final loading = _auth.loading.value;
    final user = _auth.currentUser.value;
    if (loading) return;
    if (user != null) {
      Get.offAll(() => const HomePage());
    } else {
      Get.offAll(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple splash with app name and a spinner while deciding.
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 64, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              'Student Eval',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper to allow using ever() on Rxn<T>
class _UserWrap {
  final Object? v;
  const _UserWrap(this.v);
}

class _UserWrapRx extends Rx<_UserWrap> {
  _UserWrapRx(Rxn rxn) : super(_UserWrap(rxn.value)) {
    rxn.listen((_) => value = _UserWrap(rxn.value));
  }
}
