import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../assessments/domain/models/activity_model.dart';
import '../../../assessments/domain/models/assessment_model.dart';
import '../../../assessments/domain/models/peer_evaluation_model.dart';
import '../../../assessments/domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../../assessments/data/datasources/peer_evaluation_local_datasource.dart';
import '../../../assessments/data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../../assessments/data/repositories/peer_evaluation_repository_impl.dart';
import '../../../assessments/domain/repositories/peer_evaluation_repository.dart';
import '../../../courses/domain/models/course_model.dart';

class StudentCourseGradesPage extends StatefulWidget {
  final CourseModel course;
  const StudentCourseGradesPage({super.key, required this.course});

  @override
  State<StudentCourseGradesPage> createState() => _StudentCourseGradesPageState();
}

class _StudentCourseGradesPageState extends State<StudentCourseGradesPage> {
  late final AuthController _auth;
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;

  bool _loading = true;
  List<ActivityModel> _activities = [];
  // activityId -> criterion -> value
  final Map<String, Map<String, double?>> _grades = {};

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    // ensure DI for peer evaluations use case
    if (!Get.isRegistered<GetReceivedPeerEvaluationsUseCase>()) {
      if (!Get.isRegistered<PeerEvaluationRepository>()) {
        if (!Get.isRegistered<PeerEvaluationLocalDataSource>()) {
          Get.lazyPut<PeerEvaluationLocalDataSource>(
            () => HivePeerEvaluationLocalDataSource(),
            fenix: true,
          );
        }
        if (!Get.isRegistered<PeerEvaluationRemoteDataSource>()) {
          Get.lazyPut<PeerEvaluationRemoteDataSource>(
            () => RoblePeerEvaluationRemoteDataSource(
              projectId: 'movil_993b654d20',
              debugLogging: true,
            ),
            fenix: true,
          );
        }
        Get.lazyPut<PeerEvaluationRepository>(
          () => PeerEvaluationRepositoryImpl(
            remote: Get.find<PeerEvaluationRemoteDataSource>(),
            localCache: Get.find<PeerEvaluationLocalDataSource>(),
          ),
          fenix: true,
        );
      }
      Get.lazyPut(
        () => GetReceivedPeerEvaluationsUseCase(
          Get.find<PeerEvaluationRepository>(),
        ),
        fenix: true,
      );
    }
    _getUseCase = Get.find<GetReceivedPeerEvaluationsUseCase>();

    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _loading = true);
    try {
      final courseId = widget.course.id;
      // load activities
      final abox = Hive.box(HiveBoxes.activities);
      final activities = <ActivityModel>[];
      for (final key in abox.keys) {
        final data = abox.get(key);
        if (data is Map && data['courseId'] == courseId) {
          activities.add(
            ActivityModel(
              id: data['id'],
              courseId: data['courseId'],
              categoryId: data['categoryId'],
              name: data['name'],
              description: data['description'] ?? '',
              dueDate: data['dueDate'] != null
                  ? DateTime.tryParse(data['dueDate'])
                  : null,
              visible: data['visible'] as bool? ?? true,
            ),
          );
        }
      }
      _activities = activities;

      final userId = _auth.currentUser.value?.id;
      if (userId == null) return;

      final aBox = Hive.box(HiveBoxes.assessments);

      for (final act in _activities) {
        _grades[act.id] = {
          'punctuality': null,
          'contributions': null,
          'commitment': null,
          'attitude': null,
        };

        // find assessment
        AssessmentModel? asm;
        for (final k in aBox.keys) {
          final d = aBox.get(k);
          if (d is Map && d['activityId'] == act.id) {
            asm = AssessmentModel(
              id: d['id'],
              courseId: d['courseId'],
              activityId: d['activityId'],
              title: d['title'] ?? '',
              durationMinutes: d['durationMinutes'] ?? 60,
              startAt: DateTime.tryParse(d['startAt'] ?? '') ?? DateTime.now(),
              gradesVisible: d['gradesVisible'] as bool? ?? false,
              cancelled: d['cancelled'] as bool? ?? false,
            );
            break;
          }
        }
        if (asm == null || asm.cancelled) continue;

        try {
          final evals = await _getUseCase(
            assessmentId: asm.id,
            evaluateeId: userId,
          );
          if (evals.isEmpty) continue;
          double avg(num Function(PeerEvaluationModel) sel) {
            final sum = evals.fold<num>(0, (p, e) => p + sel(e));
            return sum / evals.length;
          }

          final p = avg((e) => e.punctuality);
          final c = avg((e) => e.contributions);
          final cm = avg((e) => e.commitment);
          final a = avg((e) => e.attitude);

          _grades[act.id]!['punctuality'] = p;
          _grades[act.id]!['contributions'] = c;
          _grades[act.id]!['commitment'] = cm;
          _grades[act.id]!['attitude'] = a;
        } catch (_) {
          // leave nulls
        }
      }
    } catch (e, st) {
      debugPrint('Error loading student grades: $e');
      debugPrint('$st');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _activityAverage(String activityId) {
    final map = _grades[activityId];
    if (map == null) return null;
    final vals = map.values.whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((x, y) => x + y) / vals.length;
  }

  double? _criterionAverage(String criterion) {
    final vals = _grades.values.map((m) => m[criterion]).whereType<double>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((x, y) => x + y) / vals.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Mis notas - ${widget.course.name}'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _activities.isEmpty
              ? const Center(child: Text('No hay actividades en este curso'))
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header
                        Row(
                          children: const [
                            SizedBox(
                              width: 300,
                              child: Text('Actividad', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            SizedBox(width: 140, child: Text('Puntualidad', style: TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 140, child: Text('Contribuciones', style: TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 140, child: Text('Compromiso', style: TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 140, child: Text('Actitud', style: TextStyle(fontWeight: FontWeight.w600))),
                            SizedBox(width: 140, child: Text('Promedio', style: TextStyle(fontWeight: FontWeight.w700))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final a in _activities) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(width: 300, child: Text(a.name)),
                                SizedBox(
                                  width: 140,
                                  child: Text(_grades[a.id]?['punctuality']?.toStringAsFixed(1) ?? '--'),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Text(_grades[a.id]?['contributions']?.toStringAsFixed(1) ?? '--'),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Text(_grades[a.id]?['commitment']?.toStringAsFixed(1) ?? '--'),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Text(_grades[a.id]?['attitude']?.toStringAsFixed(1) ?? '--'),
                                ),
                                SizedBox(
                                  width: 140,
                                  child: Text(_activityAverage(a.id)?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // final averages row
                        Row(
                          children: [
                            const SizedBox(width: 300, child: Text('Promedio', style: TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(width: 140, child: Text(_criterionAverage('punctuality')?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(width: 140, child: Text(_criterionAverage('contributions')?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(width: 140, child: Text(_criterionAverage('commitment')?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontWeight: FontWeight.w700))),
                            SizedBox(width: 140, child: Text(_criterionAverage('attitude')?.toStringAsFixed(1) ?? '--', style: const TextStyle(fontWeight: FontWeight.w700))),
                            // overall average across criteria
                            SizedBox(
                              width: 140,
                              child: Text(
                                (() {
                                  final vals = [
                                    _criterionAverage('punctuality'),
                                    _criterionAverage('contributions'),
                                    _criterionAverage('commitment'),
                                    _criterionAverage('attitude'),
                                  ].whereType<double>().toList();
                                  if (vals.isEmpty) return '--';
                                  final v = vals.reduce((x, y) => x + y) / vals.length;
                                  return v.toStringAsFixed(1);
                                })(),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
