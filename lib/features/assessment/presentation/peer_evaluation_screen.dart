import 'package:flutter/material.dart';
import '../domain/criterion.dart';
import 'assessment_controller.dart';

class PeerEvaluationScreen extends StatefulWidget {
  final String assessmentId;
  final String currentUserId;
  final List<String> peerUserIds; // peers to evaluate (excluding current)
  const PeerEvaluationScreen({
    super.key,
    required this.assessmentId,
    required this.currentUserId,
    required this.peerUserIds,
  });

  @override
  State<PeerEvaluationScreen> createState() => _PeerEvaluationScreenState();
}

class _PeerEvaluationScreenState extends State<PeerEvaluationScreen> {
  final Map<String, Map<String, int>> _scores =
      {}; // peerId -> criterion -> score
  final Map<String, TextEditingController> _commentCtrls = {};
  final Set<String> _submittedPeers = {};
  late AssessmentController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    for (final peer in widget.peerUserIds) {
      _scores[peer] = {};
      _commentCtrls[peer] = TextEditingController();
    }
    _controller = AssessmentController();
  }

  @override
  void dispose() {
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _setScore(String peerId, String criterionKey, int value) {
    setState(() => _scores[peerId]![criterionKey] = value);
  }

  bool _allComplete() {
    if (widget.peerUserIds.isEmpty) return false;
    for (final peer in widget.peerUserIds) {
      for (final c in criteriaList) {
        final v = _scores[peer]![c.key];
        if (v == null || !allowedCriterionLevels.contains(v)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      for (final peer in widget.peerUserIds) {
        if (_submittedPeers.contains(peer)) continue;
        final scores = _scores[peer]!;
        // asegurar completitud
        for (final c in criteriaList) {
          if (!scores.containsKey(c.key)) {
            throw Exception('Faltan criterios para $peer');
          }
        }
        final stored = await _controller.submitEvaluation(
          assessmentId: widget.assessmentId,
          evaluatorUserId: widget.currentUserId,
          targetUserId: peer,
          criteriaScores: scores,
          comment: _commentCtrls[peer]!.text.trim().isEmpty
              ? null
              : _commentCtrls[peer]!.text.trim(),
        );
        if (stored != null) {
          _submittedPeers.add(peer);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Evaluaciones enviadas')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluar compañeros')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecciona un nivel (2–5) para cada criterio por compañero. Niveles más altos indican mejor desempeño.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (widget.peerUserIds.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'No hay compañeros en tu grupo para evaluar.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else ...[
            for (final peer in widget.peerUserIds) _buildPeerCard(peer),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: !_allComplete() || _submitting
                  ? null
                  : () => _submit(),
              icon: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _submitting
                    ? 'Enviando...'
                    : _allComplete()
                    ? 'Enviar evaluaciones'
                    : 'Completa todos los criterios',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeerCard(String peerId) {
    final submitted = _submittedPeers.contains(peerId);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Compañero: $peerId',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (submitted)
                  const Chip(
                    label: Text('Enviado'),
                    avatar: Icon(Icons.check, size: 16, color: Colors.green),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (final c in criteriaList)
              _buildCriterionRow(peerId, c.key, c.label),
            TextField(
              controller: _commentCtrls[peerId],
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
              ),
              maxLines: 2,
              enabled: !submitted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriterionRow(String peerId, String key, String title) {
    final submitted = _submittedPeers.contains(peerId);
    final current = _scores[peerId]![key];
    return Row(
      children: [
        Expanded(child: Text(title)),
        for (final level in allowedCriterionLevels)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ChoiceChip(
              label: Text(level.toString()),
              selected: current == level,
              onSelected: submitted
                  ? null
                  : (_) => _setScore(peerId, key, level),
            ),
          ),
      ],
    );
  }
}
