import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/local/local_repository.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<LocalRepository>(context);
    final user = repo.currentUser;
    final invitations = user == null ? [] : repo.listInvitationsForUser(user.email);
    return Scaffold(
      appBar: AppBar(title: const Text('Invitaciones')),
      body: ListView.builder(
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          final c = invitations[index];
          return ListTile(
            title: Text(c.name),
            subtitle: Text('Profesor: ${c.teacherId} - Código: ${c.registrationCode}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(
                onPressed: () async {
                  if (user == null) return;
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await repo.acceptInvitation(c.id, user.id);
                  messenger.showSnackBar(SnackBar(content: Text(ok ? 'Invitación aceptada' : 'No se pudo aceptar')));
                  setState(() {});
                },
                child: const Text('Aceptar'),
              ),
            ]),
          );
        },
      ),
    );
  }
}
