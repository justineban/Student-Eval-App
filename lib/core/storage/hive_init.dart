import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  // Register adapters here if/when needed.
  await Future.wait([
    Hive.openBox(HiveBoxes.users),
    Hive.openBox(HiveBoxes.session),
    Hive.openBox(HiveBoxes.courses),
    Hive.openBox(HiveBoxes.teacherCourses),
  ]);
}
