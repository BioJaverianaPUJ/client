import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';
import '../widgets/post_card.dart';
import '../services/api_exception.dart';
import '../theme/bio_theme.dart';
import 'reports_screen.dart';

/// Motivos de denuncia definidos en la Subsección 3.1.1 del SRS.
const reportReasons = <(String, IconData, String)>[
  ('Acoso', Icons.person_off_outlined, 'Intimidación o ataques a una persona'),
  (
    'Discriminación',
    Icons.do_not_disturb_on_outlined,
    'Odio o exclusión por identidad u origen',
  ),
  (
    'Contenido violento',
    Icons.warning_amber_rounded,
    'Violencia explícita o amenazas',
  ),
  (
    'Contenido sexual',
    Icons.visibility_off_outlined,
    'Desnudos o contenido sexual',
  ),
  ('Spam', Icons.campaign_outlined, 'Publicidad, enlaces o mensajes repetidos'),
  (
    'Información falsa',
    Icons.report_gmailerrorred_outlined,
    'Datos engañosos sobre la biodiversidad u otros temas',
  ),
];

/// Abre la hoja para denunciar una publicación o un comentario (RF-29).
Future<void> reportContent(
  BuildContext context,
  String id, {
  required bool comment,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: BioTheme.backgroundDeep,
  showDragHandle: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _ReportSheet(id: id, comment: comment),
);

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.id, required this.comment});
  final String id;
  final bool comment;
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _text = TextEditingController();
  String? _reason, _error;
  bool _busy = false, _sent = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(context).community.report(
        widget.id,
        comment: widget.comment,
        reason: reason,
        text: _text.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code == 'REPORT_ALREADY_EXISTS' || e.statusCode == 409
            ? 'Ya denunciaste este contenido. Puedes ver su estado en «Mis denuncias».'
            : e.statusCode == 404
            ? 'Este contenido ya no está disponible.'
            : e.message,
      );
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _done() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BioTheme.lime.withValues(alpha: 0.16),
          ),
          child: const Icon(
            Icons.verified_user_outlined,
            color: BioTheme.lime,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Gracias por avisarnos',
          style: TextStyle(
            color: BioTheme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Un administrador revisará tu denuncia. Puedes seguir su estado en «Mis denuncias», desde la configuración de tu perfil.',
          textAlign: TextAlign.center,
          style: TextStyle(color: BioTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.push(
                    MaterialPageRoute(builder: (_) => const ReportsScreen()),
                  );
                },
                child: const Text('Mis denuncias'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Listo'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: _sent
            ? _done()
            : ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.85,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    Text(
                      widget.comment
                          ? 'Denunciar comentario'
                          : 'Denunciar publicación',
                      style: const TextStyle(
                        color: BioTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '¿Por qué quieres denunciarlo? Tu denuncia es anónima para quien publicó el contenido.',
                      style: TextStyle(
                        color: BioTheme.textMuted,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (label, icon, help) in reportReasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: _reason == label
                              ? BioTheme.lime.withValues(alpha: 0.14)
                              : Colors.white.withValues(alpha: 0.04),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: _reason == label
                                  ? BioTheme.lime
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _busy
                                ? null
                                : () => setState(() => _reason = label),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    size: 22,
                                    color: _reason == label
                                        ? BioTheme.lime
                                        : BioTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          label,
                                          style: const TextStyle(
                                            color: BioTheme.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          help,
                                          style: const TextStyle(
                                            color: BioTheme.textMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    _reason == label
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_unchecked,
                                    color: _reason == label
                                        ? BioTheme.lime
                                        : BioTheme.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _text,
                      enabled: !_busy,
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Descripción (opcional)',
                        hintText: 'Cuéntanos más para ayudar a la revisión.',
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: BioTheme.danger),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _busy || _reason == null ? null : _send,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.flag_outlined),
                      label: Text(_busy ? 'Enviando…' : 'Enviar denuncia'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Publicación individual con los comentarios ya desplegados.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.post});
  final CommunityPost post;
  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Publicación',
    body: ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        PostCard(
          post: post,
          initiallyShowComments: true,
          onChanged: () => Navigator.maybePop(context),
        ),
      ],
    ),
  );
}
