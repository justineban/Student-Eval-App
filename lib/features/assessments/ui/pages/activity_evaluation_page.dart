import 'package:flutter/material.dart';
import '../../domain/models/activity_model.dart';

class ActivityEvaluationPage extends StatelessWidget {
  final ActivityModel activity;
  const ActivityEvaluationPage({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluación')),
      body: Center(
        child: Text('Evaluación para: ${activity.name}'),
      ),
    );
  }
}
