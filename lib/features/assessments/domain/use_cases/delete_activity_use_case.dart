import '../repositories/activity_repository.dart';

class DeleteActivityUseCase {
  final ActivityRepository repository;
  DeleteActivityUseCase(this.repository);

  Future<void> call(String id) => repository.deleteActivity(id);
}
