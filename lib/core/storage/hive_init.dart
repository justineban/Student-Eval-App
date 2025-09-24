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
    Hive.openBox(HiveBoxes.categories),
    Hive.openBox(HiveBoxes.activities),
    Hive.openBox(HiveBoxes.assessments),
    Hive.openBox(HiveBoxes.groups),
  ]);

  // One-time lightweight migration: move any assessment_* records out of activities box
  try {
    final activitiesBox = Hive.box(HiveBoxes.activities);
    final assessmentsBox = Hive.box(HiveBoxes.assessments);
    final keys = activitiesBox.keys.toList(growable: false);
    for (final key in keys) {
      // Copy records that were previously stored with these prefixes
      if (key is String && (key.startsWith('assessment_') || key.startsWith('assessment_by_activity_'))) {
        final value = activitiesBox.get(key);
        await assessmentsBox.put(key, value);
        await activitiesBox.delete(key);
      }
    }
  } catch (_) {
    // best-effort; ignore migration errors
  }
}
