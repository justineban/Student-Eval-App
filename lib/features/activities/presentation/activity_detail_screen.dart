import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:proyecto_movil/core/utils/local_repository.dart';
import 'package:proyecto_movil/core/entities/category.dart';
import '../controllers/activities_controller.dart';
import '../domain/activity_entity.dart';
import '../../assessment/presentation/assessment_controller.dart';
import '../../assessment/presentation/peer_evaluation_screen.dart';

class ActivityDetailScreen extends StatefulWidget {
  final String activityId;
  final String courseId;
  const ActivityDetailScreen({
    super.key,
    required this.activityId,
    required this.courseId,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late final ActivitiesController controller;
  late final AssessmentController _assessmentController;
  Activity? _activity;
  bool _editing = false;
  bool _dirty = false; // indica si hubo cambios
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    controller = ActivitiesController();
    controller.addListener(_onChange);
    _assessmentController = AssessmentController();
    _assessmentController.addListener(_onChange);
    _load();
  }

  Future<void> _load() async {
    final act = await controller.getById(widget.activityId);
    if (act != null && mounted) {
      final repo = Provider.of<LocalRepository>(context, listen: false);
      _activity = act;
      _titleCtrl.text = act.title;
      _descCtrl.text = act.description;
      _dueDate = act.dueDate;
      _selectedCategory = repo.categoriesBox.get(act.categoryId);
      setState(() {});
      // cargar assessment asociado (si existe)
      await _assessmentController.loadAssessment(widget.activityId);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    controller.dispose();
    _assessmentController.removeListener(_onChange);
    _assessmentController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _onChange() => setState(() {});

  Future<void> _saveChanges() async {
    if (_activity == null) return;
    _activity!.title = _titleCtrl.text.trim();
    _activity!.description = _descCtrl.text.trim();
    _activity!.dueDate = _dueDate;
    await controller.updateActivity(_activity!);
    if (mounted) {
      setState(() {
        _editing = false;
        _dirty = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      initialDate: _dueDate ?? now,
    );
    if (picked != null) {
      final existing = _dueDate;
      final hour = existing?.hour ?? 0;
      final minute = existing?.minute ?? 0;
      setState(
        () => _dueDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          hour,
          minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final base = _dueDate ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (picked != null) {
      setState(
        () => _dueDate = DateTime(
          base.year,
          base.month,
          base.day,
          picked.hour,
          picked.minute,
        ),
      );
    }
  }

  Future<void> _deleteActivity() async {
    if (_activity == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text('Esta acción no se puede deshacer. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await controller.deleteActivity(_activity!.id);
      if (mounted) {
        Navigator.pop(context, true); // indica cambio para refrescar lista
      }
    }
  }

  Future<void> _changeCategory(Category newCat) async {
    if (_activity == null) return;
    await controller.changeActivityCategory(_activity!, newCat.id);
    final repo = Provider.of<LocalRepository>(context, listen: false);
    _selectedCategory = repo.categoriesBox.get(newCat.id);
    await _load();
    _dirty = true;
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final course = repo.coursesBox.get(widget.courseId);
    final isCreator =
        user != null && course != null && user.id == course.teacherId;
    final categories = repo.categoriesBox.values
        .where((c) => c.courseId == widget.courseId)
        .toList();

    if (_activity == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _dirty);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Editar actividad' : 'Actividad'),
          actions: [
            if (isCreator && _editing)
              IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              if (_editing)
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título'),
                )
              else
                Text(
                  _activity!.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              Text('Categoría', style: TextStyle(color: Colors.grey.shade700)),
              if (_editing)
                DropdownButton<Category>(
                  value: _selectedCategory,
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c.name)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      _selectedCategory = v;
                      _changeCategory(v);
                    }
                  },
                )
              else
                Text(_selectedCategory?.name ?? '—'),
              const SizedBox(height: 16),
              Text(
                'Descripción',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              _editing
                  ? TextField(
                      controller: _descCtrl,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _activity!.description.isEmpty
                            ? 'Sin descripción'
                            : _activity!.description,
                      ),
                    ),
              const SizedBox(height: 16),
              Text(
                'Fecha límite',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? 'No establecida'
                          : _formatDateTime(_dueDate!),
                    ),
                  ),
                  if (_editing) ...[
                    IconButton(
                      tooltip: 'Elegir fecha',
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                    IconButton(
                      tooltip: 'Elegir hora',
                      icon: const Icon(Icons.schedule),
                      onPressed: _pickTime,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              if (isCreator && !_editing)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
              if (isCreator && !_editing)
                TextButton.icon(
                  onPressed: _deleteActivity,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 32),
              _buildAssessmentSection(isCreator),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final two = (int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Widget _buildAssessmentSection(bool isCreator) {
    final assessment = _assessmentController.assessmentForActivity(
      widget.activityId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assessment (Evaluación de pares)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        if (_assessmentController.loading)
          const Center(child: CircularProgressIndicator()),
        if (_assessmentController.error != null)
          Text(
            'Error: ${_assessmentController.error}',
            style: const TextStyle(color: Colors.red),
          ),
        if (assessment == null && !_assessmentController.loading)
          isCreator
              ? ElevatedButton.icon(
                  onPressed: _openLaunchAssessmentDialog,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Lanzar assessment'),
                )
              : const Text(
                  'El docente aún no ha lanzado el assessment.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
        if (assessment != null)
          _buildAssessmentStatusCard(assessment, isCreator),
      ],
    );
  }

  Widget _buildAssessmentStatusCard(assessment, bool isCreator) {
    final repo = Provider.of<LocalRepository>(context, listen: false);
    final user = repo.currentUser;
    // peers reales (si usuario es estudiante)
    List<String> peers = [];
    if (user != null && !isCreator) {
      // obtener categoría de la actividad y grupos de esa categoría
      final categoryId = _activity?.categoryId;
      if (categoryId != null) {
        final groups = repo.listGroupsForCategory(categoryId);
        // encontrar grupo que contiene al user
        final group = groups
            .where((g) => g.memberIds.contains(user.id))
            .firstOrNull;
        if (group != null) {
          peers = group.memberIds.where((id) => id != user.id).toList();
        }
      }
    }
    final remaining = assessment.isExpired
        ? 'Expirado'
        : '${assessment.remainingMinutes} min restantes';
    final canEvaluate =
        !isCreator && user != null && !assessment.isExpired && peers.isNotEmpty;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    assessment.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: assessment.isExpired
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    assessment.isExpired ? 'Cerrado' : 'Abierto',
                    style: TextStyle(
                      color: assessment.isExpired
                          ? Colors.red.shade800
                          : Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Duración: ${assessment.durationMinutes} min'),
            Text('Creado: ${_formatDateTime(assessment.createdAt)}'),
            if (assessment.closedAt != null)
              Text('Cerrado: ${_formatDateTime(assessment.closedAt!)}'),
            Text(
              'Acceso a resultados: ' +
                  (assessment.publicResults ? 'Públicos' : 'Solo docente'),
            ),
            const SizedBox(height: 8),
            Text(
              remaining,
              style: TextStyle(
                color: assessment.isExpired ? Colors.red : Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (isCreator && !assessment.isExpired)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _assessmentController.closeAssessment(
                        widget.activityId,
                      );
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Cerrar'),
                  ),
                if (canEvaluate)
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PeerEvaluationScreen(
                            assessmentId: assessment.id,
                            currentUserId: user.id,
                            peerUserIds: peers,
                          ),
                        ),
                      );
                    },
                    child: const Text('Evaluar pares'),
                  )
                else if (!isCreator)
                  Tooltip(
                    message: assessment.isExpired
                        ? 'El assessment ya expiró'
                        : peers.isEmpty
                        ? 'No hay compañeros en tu grupo'
                        : 'No disponible',
                    child: OutlinedButton(
                      onPressed: null,
                      child: const Text('Evaluar pares'),
                    ),
                  ),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Navegar a resultados (pendiente)
                  },
                  child: const Text('Resultados'),
                ),
                IconButton(
                  tooltip: 'Refrescar assessment',
                  onPressed: () async {
                    await _assessmentController.loadAssessment(
                      widget.activityId,
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLaunchAssessmentDialog() async {
    final nameCtrl = TextEditingController(text: 'Evaluación de pares');
    final durationCtrl = TextEditingController(text: '30');
    bool publicResults = true;
    String unit = 'min'; // min | horas
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Lanzar assessment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: durationCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duración',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: unit,
                      items: const [
                        DropdownMenuItem(value: 'min', child: Text('Min')),
                        DropdownMenuItem(value: 'h', child: Text('Horas')),
                      ],
                      onChanged: (v) => setSt(() => unit = v ?? 'min'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Resultados visibles para estudiantes'),
                  value: publicResults,
                  onChanged: (v) => setSt(() => publicResults = v),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Los criterios están predefinidos: Puntualidad, Contribuciones, Compromiso, Actitud (niveles 2–5).',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lanzar'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      final raw = int.tryParse(durationCtrl.text.trim());
      if (raw == null || raw <= 0) return;
      final durationMinutes = unit == 'min' ? raw : raw * 60;
      await _assessmentController.launchAssessment(
        activityId: widget.activityId,
        name: nameCtrl.text.trim().isEmpty
            ? 'Evaluación de pares'
            : nameCtrl.text.trim(),
        durationMinutes: durationMinutes,
        publicResults: publicResults,
      );
    }
    nameCtrl.dispose();
    durationCtrl.dispose();
  }
}
