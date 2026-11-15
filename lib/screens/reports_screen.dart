import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Map<String, dynamic>>> _reports;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reports = AppScope.read(context).community.myReports();
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Mis denuncias',
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _reports,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return StatusPanel(
            title: 'No pudimos cargar tus denuncias',
            message: messageFor(snapshot.error!),
            action: () => setState(
              () => _reports = AppScope.read(context).community.myReports(),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const StatusPanel(
            title: 'Sin denuncias',
            message: 'Aquí podrás consultar los reportes que envíes.',
          );
        }
        const states = {
          'PENDING': 'Pendiente',
          'UNDER_REVIEW': 'En revisión',
          'RESOLVED': 'Resuelta',
          'REJECTED': 'Descartada',
        };
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final r in snapshot.data!)
              BioGlassCard(
                child: ListTile(
                  title: Text(r['reason'] as String? ?? ''),
                  subtitle: Text(states[r['status']] ?? 'Estado desconocido'),
                  leading: const Icon(Icons.flag_outlined),
                ),
              ),
          ],
        );
      },
    ),
  );
}
