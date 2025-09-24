import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get/get.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/assessment_model.dart';
import '../controllers/activity_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/assessment_controller.dart';

class ActivityDetailPage extends StatefulWidget {
  final ActivityModel activity;
  const ActivityDetailPage({super.key, required this.activity});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final ActivityController _activityController;
  late final CategoryController _categoryController;
  late final AssessmentController _assessmentController;

  final _createTitleCtrl = TextEditingController();
  final _createDurationCtrl = TextEditingController(text: '60');
  bool _createGradesVisible = true;

  bool _panelOpen = false;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _activityController = Get.find<ActivityController>();
    _categoryController = Get.find<CategoryController>();
    if (!Get.isRegistered<AssessmentController>()) {
      // Fallback in case binding hasn't registered it yet
      Get.put(
        AssessmentController(
          createUseCase: Get.find(),
          getByActivityUseCase: Get.find(),
          updateUseCase: Get.find(),
          deleteByActivityUseCase: Get.find(),
        ),
        permanent: true,
      );
    }
    _assessmentController = Get.find<AssessmentController>();
    // Load any existing assessment for this activity
    _assessmentController.loadForActivity(widget.activity.id);
    // Simple ticker to refresh countdown every second
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _createTitleCtrl.dispose();
    _createDurationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
  dynamic category;
    for (final c in _categoryController.categories) {
      if (c.id == a.categoryId) { category = c; break; }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de actividad')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Categoría: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(category?.name ?? '—'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Fecha límite: ', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(a.dueDate == null
                    ? 'Sin fecha'
                    : '${a.dueDate!.day}/${a.dueDate!.month}/${a.dueDate!.year}'),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible para estudiantes'),
              value: a.visible,
              onChanged: (v) async {
                await _activityController.toggleVisibility(a);
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 16),
            const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              a.description,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            // Assessment area
            Obx(() {
              final loading = _assessmentController.loading.value;
              final err = _assessmentController.error.value;
              final AssessmentModel? current = _assessmentController.current.value;

              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (err != null) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(err, style: const TextStyle(color: Colors.red)),
                );
              }

              if (current == null) {
                // Only a button to open creation modal
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateAssessmentDialog(context, a),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Iniciar evaluación'),
                  ),
                );
              }

              // If cancelled, inform and disable actions
              final isCancelled = current.cancelled;
              final now = DateTime.now();
              final remaining = current.endAt.difference(now);
              final remainingText = remaining.isNegative
                  ? 'Tiempo finalizado'
                  : _formatDuration(remaining);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCancelled
                          ? null
                          : () => setState(() => _panelOpen = !_panelOpen),
                      icon: Icon(_panelOpen ? Icons.expand_more : Icons.expand_less),
                      label: Text(_panelOpen ? 'Ocultar evaluación' : 'Ver evaluación'),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: _EvaluationPanel(
                      assessment: current,
                      remainingText: remainingText,
                      onToggleGrades: isCancelled ? null : () => _assessmentController.toggleGradesVisibility(),
                      onEdit: isCancelled
                          ? null
                          : () => _showEditAssessmentDialog(current),
                      onCancel: isCancelled
                          ? null
                          : () async {
                              final confirm = await _confirm(context, '¿Cancelar evaluación?', 'Se eliminará la evaluación y podrás crear una nueva.');
                              if (confirm == true) {
                                try {
                                  await _assessmentController.cancel();
                                  if (mounted) setState(() { _panelOpen = false; });
                                } catch (_) {
                                  final msg = _assessmentController.error.value ?? 'Ocurrió un error al cancelar';
                                  Get.snackbar('Error', msg);
                                }
                              }
                            },
                      onViewGrades: () {
                        // Placeholder: navigate or show grades. Hook to real grades UI when available.
                        Get.snackbar('Notas', 'Aquí se mostrarán las notas de la evaluación');
                      },
                    ),
                    crossFadeState: _panelOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                  if (isCancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Evaluación cancelada', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final total = d.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _showEditAssessmentDialog(AssessmentModel a) async {
    final titleCtrl = TextEditingController(text: a.title);
    final durationCtrl = TextEditingController(text: a.durationMinutes.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duración (minutos)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      final title = titleCtrl.text.trim();
      final minutes = int.tryParse(durationCtrl.text.trim());
      if (title.isEmpty || minutes == null || minutes <= 0) {
        Get.snackbar('Datos inválidos', 'Ingresa un título y duración válidos');
        return;
      }
      await _assessmentController.updateMeta(title: title, durationMinutes: minutes);
      if (mounted) setState(() {});
    }
  }

  Future<bool?> _confirm(BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Sí')),
        ],
      ),
    );
  }

  Future<void> _openCreateAssessmentDialog(BuildContext context, ActivityModel a) async {
    _createTitleCtrl.text = '';
    _createDurationCtrl.text = '60';
    _createGradesVisible = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _createTitleCtrl,
              decoration: const InputDecoration(labelText: 'Título de la evaluación'),
            ),
            TextField(
              controller: _createDurationCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duración (minutos)'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Notas visibles para estudiantes'),
                const SizedBox(width: 8),
                StatefulBuilder(
                  builder: (ctx2, setState2) => Switch(
                    value: _createGradesVisible,
                    onChanged: (v) => setState2(() => _createGradesVisible = v),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok == true) {
      final title = _createTitleCtrl.text.trim();
      final minutes = int.tryParse(_createDurationCtrl.text.trim());
      if (title.isEmpty || minutes == null || minutes <= 0) {
        Get.snackbar('Datos incompletos', 'Ingresa título y duración válidos');
        return;
      }
      final created = await _assessmentController.create(
        courseId: a.courseId,
        activityId: a.id,
        title: title,
        durationMinutes: minutes,
        startAt: DateTime.now(),
        gradesVisible: _createGradesVisible,
      );
      if (created != null && mounted) {
        setState(() { _panelOpen = true; });
      }
    }
  }
}

class _EvaluationPanel extends StatelessWidget {
  final AssessmentModel assessment;
  final String remainingText;
  final VoidCallback? onToggleGrades;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onViewGrades;

  const _EvaluationPanel({
    required this.assessment,
    required this.remainingText,
    this.onToggleGrades,
    this.onEdit,
    this.onCancel,
    this.onViewGrades,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_turned_in_outlined),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  assessment.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Límite: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${assessment.durationMinutes} min'),
              const SizedBox(width: 16),
              const Text('Restante: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(remainingText),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Notas visibles'),
              const SizedBox(width: 8),
              Switch(
                value: assessment.gradesVisible,
                onChanged: onToggleGrades == null ? null : (_) => onToggleGrades!(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewGrades,
                  icon: const Icon(Icons.grade_outlined),
                  label: const Text('Ver notas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCancel,
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
