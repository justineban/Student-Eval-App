import '../repositories/activity_repository.dart';
import '../models/activity_model.dart';

class GetActivitiesUseCase {
  final ActivityRepository repository;
  GetActivitiesUseCase(this.repository);

  Future<List<ActivityModel>> call(String courseId) => repository.getActivitiesByCourse(courseId);
}
