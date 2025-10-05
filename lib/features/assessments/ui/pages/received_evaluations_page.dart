import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/ui/widgets/app_top_bar.dart';
import '../../../auth/ui/controllers/auth_controller.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/assessment_model.dart';
import '../../domain/models/peer_evaluation_model.dart';
import '../../domain/use_cases/get_received_peer_evaluations_use_case.dart';
import '../../data/datasources/peer_evaluation_local_datasource.dart';
import '../../data/datasources/peer_evaluation_remote_roble_datasource.dart';
import '../../data/repositories/peer_evaluation_repository_impl.dart';
import '../../domain/repositories/peer_evaluation_repository.dart';

class ReceivedEvaluationsPage extends StatefulWidget {
  final ActivityModel activity;
  final AssessmentModel assessment;
  const ReceivedEvaluationsPage({
    super.key,
    required this.activity,
    required this.assessment,
  });

  @override
  State<ReceivedEvaluationsPage> createState() =>
      _ReceivedEvaluationsPageState();
}

class _ReceivedEvaluationsPageState extends State<ReceivedEvaluationsPage> {
  late final AuthController _auth;
  late final GetReceivedPeerEvaluationsUseCase _getUseCase;
  late final AuthLocalDataSource _authLocal;
  final ScrollController _hScrollCtrl = ScrollController();

  Future<List<PeerEvaluationModel>>? _future;

  @override
  void initState() {
    super.initState();
    _auth = Get.find<AuthController>();
    // Defensive DI: ensure the use case/repo/datasource are registered
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
    _authLocal = Get.find<AuthLocalDataSource>();
    final userId = _auth.currentUser.value?.id ?? '';
    _future = _getUseCase(
      assessmentId: widget.assessment.id,
      evaluateeId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Notas recibidas'),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<PeerEvaluationModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final list = snapshot.data ?? const <PeerEvaluationModel>[];
            if (list.isEmpty) {
              return const _EmptyReceived();
            }

            // Compute averages
            double avg(num Function(PeerEvaluationModel) sel) {
              if (list.isEmpty) return double.nan;
              final sum = list.fold<num>(0, (p, e) => p + sel(e));
              return sum / list.length;
            }

            final avgP = avg((e) => e.punctuality);
            final avgC = avg((e) => e.contributions);
            final avgCm = avg((e) => e.commitment);
            final avgA = avg((e) => e.attitude);

            String fmt(double d) => d.isNaN ? '--' : d.toStringAsFixed(1);

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
                        constraints: const BoxConstraints(minWidth: 760),
                        child: DataTable(
                          columnSpacing: 12,
                          columns: const [
                            DataColumn(label: Text('Evaluador')),
                            DataColumn(label: Text('Puntualidad')),
                            DataColumn(label: Text('Contribuciones')),
                            DataColumn(label: Text('Commitment')),
                            DataColumn(label: Text('Actitud')),
                          ],
                          rows: [
                            for (final e in list)
                              DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: _EvaluatorName(
                                        userId: e.evaluatorId,
                                        authLocal: _authLocal,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(e.punctuality.toString())),
                                  DataCell(Text(e.contributions.toString())),
                                  DataCell(Text(e.commitment.toString())),
                                  DataCell(Text(e.attitude.toString())),
                                ],
                              ),
                            // Average row
                            DataRow(
                              cells: [
                                const DataCell(
                                  Text(
                                    'Promedio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(Text(fmt(avgP))),
                                DataCell(Text(fmt(avgC))),
                                DataCell(Text(fmt(avgCm))),
                                DataCell(Text(fmt(avgA))),
                              ],
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
}

class _EmptyReceived extends StatelessWidget {
  const _EmptyReceived();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.info_outline, size: 48),
          SizedBox(height: 8),
          Text('Aún no has recibido notas de tus compañeros (--)'),
        ],
      ),
    );
  }
}

class _EvaluatorName extends StatelessWidget {
  final String userId;
  final AuthLocalDataSource authLocal;
  const _EvaluatorName({required this.userId, required this.authLocal});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: authLocal.fetchUserById(userId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name;
        return Text(
          name == null || name.trim().isEmpty ? userId : name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
