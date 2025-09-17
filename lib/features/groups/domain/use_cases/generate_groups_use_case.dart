import 'package:proyecto_movil/core/entities/group.dart';
import 'package:proyecto_movil/core/entities/category.dart';

class GenerateGroupsUseCase {
  List<Group> call(Category category, List<String> studentIds) {
    final groups = <Group>[];
    final students = List<String>.from(studentIds);
    if (students.isEmpty) return groups;
    final groupCount = (students.length / category.studentsPerGroup).ceil();
    int idx = 0;
    for (var i = 1; i <= groupCount; i++) {
      final members = category.randomAssign
          ? students.sublist(idx, (idx + category.studentsPerGroup) > students.length ? students.length : idx + category.studentsPerGroup)
          : <String>[];
      groups.add(Group(
        id: '${category.id}_g$i',
        categoryId: category.id,
        name: 'Grupo $i',
        memberIds: List<String>.from(members),
      ));
      if (category.randomAssign) idx += category.studentsPerGroup;
    }
    return groups;
  }
}
