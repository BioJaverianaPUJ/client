import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';
import 'profile_screen.dart';

Future<void> reportContent(
  BuildContext context,
  String id, {
  required bool comment,
}) async {
  final repo = AppScope.read(context).community;
  try {
    final reasons = await repo.reportReasons();
    if (!context.mounted) return;
    if (reasons.isEmpty) {
      showMessage(context, 'Los motivos de denuncia no están disponibles.');
      return;
    }
    await showDialog(
      context: context,
      builder: (_) => _ReportDialog(id: id, comment: comment, reasons: reasons),
    );
  } catch (e) {
    if (context.mounted) showMessage(context, messageFor(e));
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog({
    required this.id,
    required this.comment,
    required this.reasons,
  });
  final String id;
  final bool comment;
  final List<String> reasons;
  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _text = TextEditingController();
  String? _reason, _error;
  bool _busy = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await AppScope.read(context).community.report(
        widget.id,
        comment: widget.comment,
        reason: _reason!,
        text: _text.text.trim(),
      );
      if (mounted) {
        showMessage(context, 'Denuncia enviada para revisión.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Denunciar contenido'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Motivo'),
            items: widget.reasons
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _reason = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            enabled: !_busy,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comentario opcional'),
          ),
          if (_error != null) Text(_error!),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: _busy || _reason == null ? null : _send,
        child: const Text('Enviar denuncia'),
      ),
    ],
  );
}

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final CommunityPost post;
  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _text = TextEditingController();
  List<PostComment> _comments = [];
  PostComment? _reply, _edit;
  Object? _error;
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final comments = await AppScope.read(
        context,
      ).community.comments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = comments;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await AppScope.read(context).community.saveComment(
        widget.post.id,
        _text.text.trim(),
        id: _edit?.id,
        parentId: _reply?.id,
      );
      if (!mounted) return;
      _text.clear();
      setState(() {
        _reply = null;
        _edit = null;
      });
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(PostComment c) async {
    final repo = AppScope.read(context).community;
    if (!await confirmAction(
      context,
      'Eliminar comentario',
      'Esta acción no se puede deshacer.',
    )) {
      return;
    }
    try {
      await repo.deleteComment(widget.post.id, c.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    }
  }

  Widget _comment(PostComment c, {bool reply = false}) {
    final mine = AppScope.read(context).user?.id == c.authorId;
    return Padding(
      padding: EdgeInsets.only(left: reply ? 24 : 0),
      child: BioGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(userId: c.authorId),
                  ),
                ),
                child: Text(c.authorName),
              ),
              Text(c.text),
              Text(
                dateLabel(c.date.toLocal()),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _edit = null;
                      _reply = reply
                          ? _comments.firstWhere((v) => v.id == c.parentId)
                          : c;
                      _text.clear();
                    }),
                    child: const Text('Responder'),
                  ),
                  if (mine)
                    TextButton(
                      onPressed: () => setState(() {
                        _edit = c;
                        _reply = null;
                        _text.text = c.text;
                      }),
                      child: const Text('Editar'),
                    ),
                  if (mine)
                    TextButton(
                      onPressed: () => _delete(c),
                      child: const Text('Eliminar'),
                    ),
                  if (!mine)
                    TextButton(
                      onPressed: () =>
                          reportContent(context, c.id, comment: true),
                      child: const Text('Denunciar'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Publicación',
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          widget.post.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(widget.post.text),
        for (final image in widget.post.images)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RemotePhoto(image),
          ),
        const Divider(),
        const Text(
          'Comentarios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          StatusPanel(
            title: 'Comentarios no disponibles',
            message: messageFor(_error!),
            action: _load,
          ),
        if (!_loading && _error == null && _comments.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Sé la primera persona en comentar.'),
          ),
        for (final c in _comments.where((c) => c.parentId == null)) ...[
          _comment(c),
          for (final reply in _comments.where((r) => r.parentId == c.id))
            _comment(reply, reply: true),
        ],
        if (_reply != null || _edit != null)
          ListTile(
            title: Text(
              _edit != null
                  ? 'Editando comentario'
                  : 'Respondiendo a ${_reply!.authorName}',
            ),
            trailing: IconButton(
              tooltip: 'Cancelar edición',
              onPressed: () => setState(() {
                _reply = null;
                _edit = null;
                _text.clear();
              }),
              icon: const Icon(Icons.close),
            ),
          ),
        TextField(
          controller: _text,
          enabled: !_saving,
          minLines: 1,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Escribe un comentario'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _saving ? null : _send,
          child: Text(_edit != null ? 'Guardar comentario' : 'Comentar'),
        ),
      ],
    ),
  );
}
