import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_boxes.dart';
import '../../../courses/domain/models/course_model.dart';
import '../../../assessments/domain/models/activity_model.dart';
import '../../../assessments/domain/models/assessment_model.dart';
import '../../../assessments/domain/models/peer_evaluation_model.dart';
import '../../../assessments/domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../../assessments/data/datasources/peer_evaluation_local_datasource.dart';
import '../../../assessments/data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../../assessments/data/repositories/peer_evaluation_repository_impl.dart';
import '../../../assessments/domain/repositories/peer_evaluation_repository.dart';
import '../../../auth/data/datasources/user_remote_roble_datasource.dart';

class CourseReportPage extends StatefulWidget {
  final CourseModel course;
  const CourseReportPage({super.key, required this.course});

  @override
  State<CourseReportPage> createState() => _CourseReportPageState();
}

class _CourseReportPageState extends State<CourseReportPage> {
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;
  // use remote user API for name lookups
  final Map<String, String?> _nameCache = {};

  Future<_ReportData>? _future;
  final ScrollController _hScroll = ScrollController();

  @override
  void initState() {
    super.initState();
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
    _future = _buildReport();
    _future!.then((data) async {
      final api = Get.find<UserRemoteDataSource>();
      await Future.wait(data.studentIds.map((id) async {
        try {
          _nameCache[id] = await api.fetchNameByUserId(id);
        } catch (_) {
          _nameCache[id] = null;
        }
      }));
      if (mounted) setState(() {});
    });
  }

  Future<_ReportData> _buildReport() async {
    // Load students
    final cbox = Hive.box(HiveBoxes.courses);
    List<String> studentIds = [];
    for (final key in cbox.keys) {
      final data = cbox.get(key);
      if (data is Map && data['id'] == widget.course.id) {
        studentIds =
            (data['studentIds'] as List?)?.cast<String>() ?? <String>[];
        break;
      }
    }
    // Load activities for course
    final abox = Hive.box(HiveBoxes.activities);
    final activities = <ActivityModel>[];
    for (final key in abox.keys) {
      final data = abox.get(key);
      if (data is Map && data['courseId'] == widget.course.id) {
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
    // Load assessment per activity
    final asmBox = Hive.box(HiveBoxes.assessments);
    final Map<String, AssessmentModel> assessments = {};
    for (final a in activities) {
      for (final key in asmBox.keys) {
        final data = asmBox.get(key);
        if (data is Map && data['activityId'] == a.id) {
          assessments[a.id] = AssessmentModel(
            id: data['id'],
            courseId: data['courseId'],
            activityId: data['activityId'],
            title: data['title'] ?? '',
            durationMinutes: data['durationMinutes'] ?? 60,
            startAt: DateTime.tryParse(data['startAt'] ?? '') ?? DateTime.now(),
            gradesVisible: data['gradesVisible'] as bool? ?? false,
            cancelled: data['cancelled'] as bool? ?? false,
          );
          break;
        }
      }
    }
    // Compute grades matrix: rows=students, cols=activities
    final Map<String, Map<String, double?>> grades =
        {}; // studentId -> (activityId -> grade or null)
    for (final sid in studentIds) {
      final row = <String, double?>{};
      for (final act in activities) {
        final asm = assessments[act.id];
        if (asm == null || asm.cancelled == true) {
          row[act.id] = null;
          continue;
        }
        final evals = await _getUseCase(assessmentId: asm.id, evaluateeId: sid);
        if (evals.isEmpty) {
          row[act.id] = null;
          continue;
        }
        double avg(num Function(PeerEvaluationModel) sel) {
          final sum = evals.fold<num>(0, (p, e) => p + sel(e));
          return sum / evals.length;
        }

        final p = avg((e) => e.punctuality);
        final c = avg((e) => e.contributions);
        final cm = avg((e) => e.commitment);
        final a = avg((e) => e.attitude);
        row[act.id] = (p + c + cm + a) / 4.0;
      }
      grades[sid] = row;
    }
    return _ReportData(
      studentIds: studentIds,
      activities: activities,
      grades: grades,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Reporte • ${widget.course.name}'),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<_ReportData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            if (data == null ||
                data.activities.isEmpty ||
                data.studentIds.isEmpty) {
              return const Center(child: Text('No hay datos para mostrar'));
            }

            // Prepare columns: Activity names + 'Promedio'
            final columns = <DataColumn>[
              const DataColumn(label: Text('Estudiante')),
              ...data.activities.map((a) => DataColumn(label: Text(a.name))),
              const DataColumn(label: Text('Promedio')),
            ];

            // Rows per student
            final rows = <DataRow>[];
            for (final sid in data.studentIds) {
              final rowGrades = data.grades[sid]!;
              // Student average over non-null grades
              final vals = rowGrades.values.whereType<double>().toList();
              final studentAvg = vals.isEmpty
                  ? null
                  : (vals.reduce((x, y) => x + y) / vals.length);
              rows.add(
                DataRow(
                  cells: [
                    DataCell(
                      _StudentNameCell(userId: sid),
                    ),
                    ...data.activities.map((a) {
                      final g = rowGrades[a.id];
                      return DataCell(
                        Text(g == null ? '--' : g.toStringAsFixed(1)),
                      );
                    }),
                    DataCell(
                      Text(
                        studentAvg == null
                            ? '--'
                            : studentAvg.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Activity averages row
            final avgRowCells = <DataCell>[];
            avgRowCells.add(
              const DataCell(
                Text(
                  'Promedios',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            );
            for (final act in data.activities) {
              final vals = <double>[];
              for (final sid in data.studentIds) {
                final v = data.grades[sid]![act.id];
                if (v != null) vals.add(v);
              }
              final avg = vals.isEmpty
                  ? null
                  : (vals.reduce((x, y) => x + y) / vals.length);
              avgRowCells.add(
                DataCell(Text(avg == null ? '--' : avg.toStringAsFixed(1))),
              );
            }
            avgRowCells.add(const DataCell(Text('—'))); // empty for last column

            return Scrollbar(
              controller: _hScroll,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _hScroll,
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 240 + data.activities.length * 120,
                  ),
                  child: DataTable(
                    columnSpacing: 12,
                    columns: columns,
                    rows: [
                      ...rows,
                      DataRow(cells: avgRowCells),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReportData {
  final List<String> studentIds;
  final List<ActivityModel> activities;
  final Map<String, Map<String, double?>> grades;
  _ReportData({
    required this.studentIds,
    required this.activities,
    required this.grades,
  });
}

class _StudentNameCell extends StatelessWidget {
  final String userId;
  const _StudentNameCell({required this.userId});
  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_CourseReportPageState>();
    final name = parent?._nameCache[userId];
    return Text(name == null || name.trim().isEmpty ? userId : name);
  }
}
