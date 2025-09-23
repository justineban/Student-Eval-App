import 'package:uuid/uuid.dart';
import '../../domain/models/category_model.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource local;
  final _uuid = const Uuid();
  CategoryRepositoryImpl({required this.local});

  @override
  Future<CategoryModel> createCategory({required String courseId, required String name, required bool randomGroups, required int maxStudentsPerGroup}) async {
    final category = CategoryModel(
      id: _uuid.v4(),
      courseId: courseId,
      name: name,
      randomGroups: randomGroups,
      maxStudentsPerGroup: maxStudentsPerGroup,
    );
    return await local.save(category);
  }

  @override
  Future<List<CategoryModel>> getCategoriesByCourse(String courseId) => local.fetchByCourse(courseId);

  @override
  Future<CategoryModel?> getCategory(String id) => local.fetchById(id);
}
