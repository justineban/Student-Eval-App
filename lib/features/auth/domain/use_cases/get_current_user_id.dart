import '../repositories/auth_repository.dart';

class GetCurrentUserId {
  final AuthRepository repo;
  GetCurrentUserId(this.repo);

  String? call() => repo.getCurrentUserId();
}
