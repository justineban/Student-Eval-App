import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../auth/data/datasources/user_remote_roble_datasource.dart';
import '../../../courses/ui/controllers/group_controller.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/models/peer_evaluation_model.dart';
import '../../domain/use_cases/save_peer_evaluations_use_case.dart';
import '../../data/datasources/peer_evaluation_local_datasource.dart';
import '../../data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../data/repositories/peer_evaluation_repository_impl.dart';
import '../../domain/repositories/peer_evaluation_repository.dart';
// auth user model not required here

class ActivityEvaluationPage extends StatefulWidget {
  final ActivityModel activity;
  final AssessmentModel assessment;
  const ActivityEvaluationPage({
    super.key,
    required this.activity,
    required this.assessment,
  });

  @override
  State<ActivityEvaluationPage> createState() => _ActivityEvaluationPageState();
}

class _ActivityEvaluationPageState extends State<ActivityEvaluationPage> {
  late final CourseGroupController _groupCtrl;
  late final AuthController _auth;
  late final SavePeerEvaluationsUseCase _saveUseCase;
  final ScrollController _hScrollCtrl = ScrollController();

  final _ratings = <String, PeerEvaluationModel>{}.obs; // key by evaluateeId
  bool _saving = false;
  final Map<String, String?> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _groupCtrl = Get.find<CourseGroupController>();
    _auth = Get.find<AuthController>();
    // Defensive DI: ensure the use case is registered even after hot reloads
    if (!Get.isRegistered<SavePeerEvaluationsUseCase>()) {
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
        () => SavePeerEvaluationsUseCase(Get.find<PeerEvaluationRepository>()),
        fenix: true,
      );
    }
    _saveUseCase = Get.find<SavePeerEvaluationsUseCase>();
    // Ensure groups loaded for category and prefetch member names
    _loadGroupsAndPrefetchNames();
  }

  void _loadGroupsAndPrefetchNames() async {
    await _groupCtrl.load(widget.activity.categoryId);
    final userId = _auth.currentUser.value?.id ?? '';
    final myGroup = _groupCtrl.groups.firstWhereOrNull((g) => g.memberIds.contains(userId));
    if (myGroup == null) return;
    final peers = myGroup.memberIds.where((m) => m != userId).toList();
    await _prefetchNames(peers);
    if (mounted) setState(() {});
  }

  Future<void> _prefetchNames(List<String> ids) async {
    final api = Get.find<UserRemoteDataSource>();
    final futures = ids.map((id) async {
      try {
        final n = await api.fetchNameByUserId(id);
        _nameCache[id] = n;
      } catch (_) {
        _nameCache[id] = null;
      }
    });
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser.value?.id ?? '';
    return Scaffold(
      appBar: const AppTopBar(title: 'Evaluación de grupo'),
      body: Obx(() {
        if (_groupCtrl.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        // Find user's group in this category
        final myGroup = _groupCtrl.groups.firstWhereOrNull(
          (g) => g.memberIds.contains(userId),
        );
        if (myGroup == null) {
          return const Center(
            child: Text('No perteneces a ningún grupo para esta categoría'),
          );
        }
        final peers = myGroup.memberIds.where((m) => m != userId).toList();
        if (peers.isEmpty) {
          return const Center(child: Text('No hay compañeros para evaluar'));
        }
        // Initialize rows if not present
        for (final pid in peers) {
          _ratings.putIfAbsent(
            pid,
            () => PeerEvaluationModel(
              id: '${widget.assessment.id}_${userId}_$pid',
              assessmentId: widget.assessment.id,
              evaluatorId: userId,
              evaluateeId: pid,
              punctuality: 3,
              contributions: 3,
              commitment: 3,
              attitude: 3,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actividad: ${widget.activity.name}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Scrollbar(
                controller: _hScrollCtrl,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _hScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 760),
                    child: DataTable(
                      columnSpacing: 12,
                      columns: const [
                        DataColumn(label: Text('Integrante')),
                        DataColumn(label: Text('Puntualidad')),
                        DataColumn(label: Text('Contribuciones')),
                        DataColumn(label: Text('Commitment')),
                        DataColumn(label: Text('Actitud')),
                      ],
                      rows: [
                        for (final pid in peers)
                          DataRow(
                            cells: [
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 180,
                                  ),
                                  child: _MemberName(userId: pid, nameCache: _nameCache),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: _RatingCell(
                                    value: _ratings[pid]!.punctuality,
                                    onChanged: (v) => _ratings[pid] =
                                        _ratings[pid]!.copyWith(punctuality: v),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 110,
                                  child: _RatingCell(
                                    value: _ratings[pid]!.contributions,
                                    onChanged: (v) =>
                                        _ratings[pid] = _ratings[pid]!.copyWith(
                                          contributions: v,
                                        ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 110,
                                  child: _RatingCell(
                                    value: _ratings[pid]!.commitment,
                                    onChanged: (v) => _ratings[pid] =
                                        _ratings[pid]!.copyWith(commitment: v),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: _RatingCell(
                                    value: _ratings[pid]!.attitude,
                                    onChanged: (v) => _ratings[pid] =
                                        _ratings[pid]!.copyWith(attitude: v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar evaluación'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _saveUseCase(_ratings.values.toList());
      if (mounted) Get.snackbar('Guardado', 'Tu evaluación fue guardada');
    } catch (e) {
      if (mounted) Get.snackbar('Error', 'No se pudo guardar');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _MemberName extends StatelessWidget {
  final String userId;
  final Map<String, String?> nameCache;
  const _MemberName({required this.userId, required this.nameCache});
  @override
  Widget build(BuildContext context) {
    final name = nameCache[userId];
    return Text((name != null && name.trim().isNotEmpty) ? name : userId);
  }
}

class _RatingCell extends StatelessWidget {
  final int value; // 2..5
  final ValueChanged<int> onChanged;
  const _RatingCell({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      items: const [
        DropdownMenuItem(value: 2, child: Text('2')),
        DropdownMenuItem(value: 3, child: Text('3')),
        DropdownMenuItem(value: 4, child: Text('4')),
        DropdownMenuItem(value: 5, child: Text('5')),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
