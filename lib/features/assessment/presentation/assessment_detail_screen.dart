import 'package:flutter/material.dart';
import '../domain/assessment_entity.dart';

class AssessmentDetailScreen extends StatelessWidget {
  final Assessment assessment;
  final VoidCallback? onClose;
  const AssessmentDetailScreen({
    super.key,
    required this.assessment,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(assessment.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad: ${assessment.activityId}'),
            const SizedBox(height: 8),
            Text('Duración: ${assessment.durationMinutes} min'),
            const SizedBox(height: 8),
            Text('Estado: ${assessment.closed ? 'Cerrada' : 'Activa'}'),
            const SizedBox(height: 8),
            Text(
              'Resultados públicos: ${assessment.publicResults ? 'Sí' : 'No'}',
            ),
            const SizedBox(height: 8),
            if (assessment.closedAt != null)
              Text('Cerrada en: ${assessment.closedAt}'),
            const Spacer(),
            if (!assessment.closed)
              ElevatedButton.icon(
                onPressed: () {
                  onClose?.call();
                  Navigator.pop(context, true);
                },
                icon: const Icon(Icons.stop_circle),
                label: const Text('Cerrar evaluación'),
              ),
          ],
        ),
      ),
    );
  }
}
