import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../../../auth/data/datasources/user_remote_roble_datasource.dart';
import '../../../courses/ui/controllers/group_controller.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/models/peer_evaluation_model.dart';
import '../../domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../data/datasources/peer_evaluation_local_datasource.dart';
import '../../data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../data/repositories/peer_evaluation_repository_impl.dart';
import '../../domain/repositories/peer_evaluation_repository.dart';

class TeacherGradesPage extends StatefulWidget {
  final ActivityModel activity;
  final AssessmentModel assessment;
  const TeacherGradesPage({
    super.key,
    required this.activity,
    required this.assessment,
  });

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  late final CourseGroupController _groupCtrl;
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;
  final ScrollController _hScrollCtrl = ScrollController();
  final Map<String, String?> _nameCache = {};

  Future<List<_StudentAverages>>? _future;

  @override
  void initState() {
    super.initState();
    _groupCtrl = Get.find<CourseGroupController>();
    // Defensive DI for peer evaluation fetching
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
    _future = _computeAveragesAndPrefetch();
  }

  Future<List<_StudentAverages>> _computeAveragesAndPrefetch() async {
    final rows = await _computeAverages();
    final ids = rows.map((r) => r.userId).toSet().toList();
    final api = Get.find<UserRemoteDataSource>();
    await Future.wait(ids.map((id) async {
      try {
        _nameCache[id] = await api.fetchNameByUserId(id);
      } catch (_) {
        _nameCache[id] = null;
      }
    }));
    for (final r in rows) {
      r.displayName = _nameCache[r.userId];
    }
    return rows;
  }

  Future<List<_StudentAverages>> _computeAverages() async {
    // Ensure we have the latest groups for this category
    await _groupCtrl.load(widget.activity.categoryId);
    final catGroups = _groupCtrl.groups.toList();
    if (catGroups.isEmpty) return <_StudentAverages>[];
    final memberIds = <String>{};
    for (final g in catGroups) {
      memberIds.addAll(g.memberIds);
    }
    if (memberIds.isEmpty) return <_StudentAverages>[];

    final List<_StudentAverages> rows = [];
    await Future.wait(
      memberIds.map((uid) async {
        final list = await _getUseCase(
          assessmentId: widget.assessment.id,
          evaluateeId: uid,
        );
        double avg(num Function(PeerEvaluationModel) sel) {
          if (list.isEmpty) return double.nan;
          final sum = list.fold<num>(0, (p, e) => p + sel(e));
          return sum / list.length;
        }

        final p = avg((e) => e.punctuality);
        final c = avg((e) => e.contributions);
        final cm = avg((e) => e.commitment);
        final a = avg((e) => e.attitude);
        // total average: mean of the available criterion averages
        final comps = [p, c, cm, a].where((x) => !x.isNaN).toList();
        final total = comps.isEmpty
            ? double.nan
            : (comps.reduce((x, y) => x + y) / comps.length);
        rows.add(
          _StudentAverages(
            userId: uid,
            punctuality: p,
            contributions: c,
            commitment: cm,
            attitude: a,
            total: total,
          ),
        );
      }),
    );

    // Sort by name if possible, else by id
    rows.sort(
      (a, b) =>
          (a.displayName ?? a.userId).compareTo(b.displayName ?? b.userId),
    );
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Notas de estudiantes'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<_StudentAverages>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data ?? const <_StudentAverages>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividad: ${widget.activity.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Scrollbar(
                    controller: _hScrollCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _hScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 900),
                        child: DataTable(
                          columnSpacing: 12,
                          columns: const [
                            DataColumn(label: Text('Estudiante')),
                            DataColumn(label: Text('Puntualidad')),
                            DataColumn(label: Text('Contribuciones')),
                            DataColumn(label: Text('Commitment')),
                            DataColumn(label: Text('Actitud')),
                            DataColumn(label: Text('Promedio')),
                          ],
                          rows: [
                            if (rows.isEmpty)
                              const DataRow(
                                cells: [
                                  DataCell(
                                    Text('No hay estudiantes o notas aún'),
                                  ),
                                  DataCell(Text('--')),
                                  DataCell(Text('--')),
                                  DataCell(Text('--')),
                                  DataCell(Text('--')),
                                  DataCell(Text('--')),
                                ],
                              )
                            else
                              ...rows.map(
                                (r) => DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 220,
                                        child: _StudentName(
                                          userId: r.userId,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(_fmt(r.punctuality))),
                                    DataCell(Text(_fmt(r.contributions))),
                                    DataCell(Text(_fmt(r.commitment))),
                                    DataCell(Text(_fmt(r.attitude))),
                                    DataCell(
                                      Text(
                                        _fmt(r.total),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _fmt(double d) => d.isNaN ? '--' : d.toStringAsFixed(1);
}

class _StudentAverages {
  final String userId;
  final double punctuality;
  final double contributions;
  final double commitment;
  final double attitude;
  final double total;
  String? displayName;
  _StudentAverages({
    required this.userId,
    required this.punctuality,
    required this.contributions,
    required this.commitment,
    required this.attitude,
    required this.total,
  });
}

class _StudentName extends StatelessWidget {
  final String userId;
  const _StudentName({required this.userId});
  @override
  Widget build(BuildContext context) {
    final parent = context.findAncestorStateOfType<_TeacherGradesPageState>();
    final name = parent?._nameCache[userId];
    final text = (name == null || name.trim().isEmpty) ? userId : name;
    return Text(text);
  }
}
