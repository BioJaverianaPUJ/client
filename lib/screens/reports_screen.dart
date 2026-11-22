import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';

/// Estados de denuncia con los nombres del SRS (RF-53).
const reportStates = <String, (String, Color, IconData)>{
  'PENDING': ('No revisada', Color(0xFFE8C468), Icons.schedule_rounded),
  'UNDER_REVIEW': ('En revisión', Color(0xFF8EC5FF), Icons.manage_search),
  'RESOLVED': ('Revisada', BioTheme.lime, Icons.verified_outlined),
  'REJECTED': ('Descartada', BioTheme.textMuted, Icons.block_outlined),
};

/// Historial de denuncias realizadas por el usuario (RF-29).
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

  Future<void> _reload() async {
    final next = AppScope.read(context).community.myReports();
    setState(() => _reports = next);
    await next.catchError((Object _) => <Map<String, dynamic>>[]);
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Mis denuncias',
    body: RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ListView(
              children: [
                StatusPanel(
                  title: 'No pudimos cargar tus denuncias',
                  message: messageFor(snapshot.error!),
                  action: _reload,
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = [...snapshot.data!]
            ..sort(
              (a, b) => (b['createdAt'] as String? ?? '').compareTo(
                a['createdAt'] as String? ?? '',
              ),
            );
          if (reports.isEmpty) {
            return ListView(
              children: const [
                StatusPanel(
                  title: 'Sin denuncias',
                  message:
                      'Si ves una publicación o un comentario inapropiado, usa «Denunciar» en su menú. Aquí podrás seguir su estado.',
                  icon: Icons.flag_outlined,
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(6, 0, 6, 10),
                child: Text(
                  'Un administrador revisa cada denuncia. El estado cambia cuando se analiza o se toma una decisión.',
                  style: TextStyle(color: BioTheme.textMuted, fontSize: 13),
                ),
              ),
              for (final r in reports) _ReportCard(report: r),
            ],
          );
        },
      ),
    ),
  );
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final raw = report['reason'] as String? ?? '';
    // La app envía «Motivo: descripción» porque el backend tiene un solo campo.
    final split = raw.indexOf(': ');
    final reason = split > 0 ? raw.substring(0, split) : raw;
    final detail = split > 0 ? raw.substring(split + 2) : '';
    final (label, color, icon) =
        reportStates[report['status']] ??
        ('Estado desconocido', BioTheme.textMuted, Icons.help_outline);
    final comment = report['reportType'] == 'COMMENT';
    final user = report['reportedUserUsername'] as String?;
    final date = DateTime.tryParse(report['createdAt'] as String? ?? '');
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                comment
                    ? Icons.mode_comment_outlined
                    : Icons.article_outlined,
                size: 18,
                color: BioTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  [
                    comment ? 'Comentario' : 'Publicación',
                    if (user != null && user.isNotEmpty) 'de @$user',
                  ].join(' '),
                  style: const TextStyle(
                    color: BioTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reason,
            style: const TextStyle(
              color: BioTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
            ),
          ),
          if (detail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                detail,
                style: const TextStyle(
                  color: BioTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          if (date != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Enviada el ${dateLabel(date.toLocal())}',
                style: const TextStyle(
                  color: BioTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
