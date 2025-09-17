import 'package:flutter/material.dart';
import '../domain/use_cases/generate_groups_use_case.dart';
import '../../../core/entities/group.dart';
import '../../../core/entities/category.dart';

class GroupsController with ChangeNotifier {
  final GenerateGroupsUseCase _generateGroupsUseCase = GenerateGroupsUseCase();

  List<Group> generateGroups(Category category, List<String> studentIds) {
    return _generateGroupsUseCase(category, studentIds);
  }
}
