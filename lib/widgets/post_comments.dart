import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/community.dart';
import '../screens/post_detail_screen.dart' show reportContent;
import '../screens/profile_screen.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import 'community_widgets.dart';

/// Reacciones admitidas por el backend (ReactionType) y su emoji.
const commentReactions = <(String, String, String)>[
  ('LOVE', '❤️', 'Me encanta'),
  ('LIKE', '👍', 'Me gusta'),
  ('HAHA', '😂', 'Me divierte'),
  ('WOW', '😮', 'Me sorprende'),
  ('SAD', '😢', 'Me entristece'),
  ('ANGRY', '😠', 'Me enoja'),
];

String reactionEmoji(String code) {
  for (final r in commentReactions) {
    if (r.$1 == code) return r.$2;
  }
  return '❤️';
}

String reactionLabel(String code) {
  for (final r in commentReactions) {
    if (r.$1 == code) return r.$3;
  }
  return 'Reaccionar';
}

const loveColor = Color(0xFFFF7A8A);

/// "ahora", "5 min", "3 h", "2 d", "4 sem" o la fecha completa.
String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min';
  if (diff.inHours < 24) return '${diff.inHours} h';
  if (diff.inDays < 7) return '${diff.inDays} d';
  if (diff.inDays < 35) return '${diff.inDays ~/ 7} sem';
  return dateLabel(date.toLocal());
}

void openProfile(BuildContext context, String userId) => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
);

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.url,
    this.size = 36,
    this.ring = false,
  });
  final String name;
  final String? url;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final clean = name.trim();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BioTheme.botanical, BioTheme.iconDark],
        ),
      ),
      child: Text(
        clean.isEmpty ? '?' : clean.substring(0, 1).toUpperCase(),
        style: TextStyle(
          color: BioTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.42,
        ),
      ),
    );
    final photo = url;
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: photo == null || photo.trim().isEmpty
            ? fallback
            : Image.network(
                RemotePhoto.resolve(photo),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [BioTheme.lime, BioTheme.botanical],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: BioTheme.background,
        ),
        child: avatar,
      ),
    );
  }
}

/// Comentarios desplegados dentro de la misma publicación.
class PostCommentsSection extends StatefulWidget {
  const PostCommentsSection({
    super.key,
    required this.post,
    required this.onCountChanged,
    this.focusNode,
  });
  final CommunityPost post;
  final ValueChanged<int> onCountChanged;
  final FocusNode? focusNode;

  @override
  State<PostCommentsSection> createState() => _PostCommentsSectionState();
}

class _PostCommentsSectionState extends State<PostCommentsSection> {
  final _text = TextEditingController();
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  List<PostComment> _comments = [];
  final _openReplies = <String>{};
  final _busy = <String>{};
  PostComment? _replyTo, _editing;
  String? _replyName;
  Object? _error;
  bool _loading = true, _sending = false;
  int _visibleRoots = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  String? get _me => AppScope.read(context).user?.id;

  List<PostComment> get _roots =>
      _comments.where((c) => c.parentId == null).toList();

  List<PostComment> _repliesOf(String id) =>
      _comments.where((c) => c.parentId == id).toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AppScope.read(context).community
          .comments(widget.post.id);
      if (!mounted) return;
      setState(() => _comments = List.of(list));
      widget.onCountChanged(list.length);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _replace(PostComment comment) => setState(() {
    final i = _comments.indexWhere((c) => c.id == comment.id);
    if (i >= 0) _comments[i] = comment;
  });

  void _clearTarget() => setState(() {
    _replyTo = null;
    _replyName = null;
    _editing = null;
    _text.clear();
  });

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    final editing = _editing, replyTo = _replyTo;
    setState(() => _sending = true);
    try {
      await AppScope.read(context).community.saveComment(
        widget.post.id,
        text,
        id: editing?.id,
        parentId: editing == null ? replyTo?.id : null,
      );
      if (!mounted) return;
      _text.clear();
      _focus.unfocus();
      setState(() {
        _editing = null;
        _replyTo = null;
        _replyName = null;
        if (replyTo != null) _openReplies.add(replyTo.id);
      });
      await _load();
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Toca la misma reacción para retirarla; otra la reemplaza.
  Future<void> _react(PostComment comment, String target) async {
    final me = _me;
    if (me == null || _busy.contains(comment.id)) return;
    final repo = AppScope.read(context).community;
    final next = comment.reactionOf(me) == target ? null : target;
    HapticFeedback.selectionClick();
    setState(() => _busy.add(comment.id));
    _replace(comment.withReaction(me, next));
    try {
      await repo.react(comment.id, next);
      final fresh = await repo.comment(comment.id);
      if (mounted) _replace(fresh);
    } catch (e) {
      if (mounted) {
        _replace(comment);
        showMessage(context, messageFor(e));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(comment.id));
    }
  }

  void _startReply(PostComment comment) {
    // El servidor admite un solo nivel: las respuestas cuelgan del comentario
    // principal y mencionan a la persona.
    final root = comment.parentId == null
        ? comment
        : _comments.firstWhere(
            (c) => c.id == comment.parentId,
            orElse: () => comment,
          );
    setState(() {
      _editing = null;
      _replyTo = root;
      _replyName = comment.authorName;
      _text.text = '@${comment.authorName} ';
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    });
    _focus.requestFocus();
  }

  void _startEdit(PostComment comment) {
    setState(() {
      _replyTo = null;
      _replyName = null;
      _editing = comment;
      _text.text = comment.text;
      _text.selection = TextSelection.collapsed(offset: _text.text.length);
    });
    _focus.requestFocus();
  }

  Future<void> _delete(PostComment comment) async {
    if (!await confirmAction(
      context,
      'Eliminar comentario',
      'Esta acción no se puede deshacer.',
    )) {
      return;
    }
    if (!mounted) return;
    try {
      await AppScope.read(context).community
          .deleteComment(widget.post.id, comment.id);
      if (mounted) await _load();
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    }
  }

  Future<void> _options(PostComment comment) async {
    final mine = _me == comment.authorId;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BioTheme.backgroundDeep,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Responder'),
              onTap: () => Navigator.pop(sheet, 'reply'),
            ),
            if (mine)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(sheet, 'edit'),
              ),
            if (mine)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: BioTheme.danger,
                ),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: BioTheme.danger),
                ),
                onTap: () => Navigator.pop(sheet, 'delete'),
              ),
            if (!mine)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Denunciar'),
                onTap: () => Navigator.pop(sheet, 'report'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'reply':
        _startReply(comment);
      case 'edit':
        _startEdit(comment);
      case 'delete':
        await _delete(comment);
      case 'report':
        await reportContent(context, comment.id, comment: true);
    }
  }

  Future<void> _showPicker(BuildContext anchor, PostComment comment) async {
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    HapticFeedback.mediumImpact();
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final chosen = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar reacciones',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (_, _, _) =>
          _ReactionPicker(anchor: rect, current: comment.reactionOf(_me)),
      transitionBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
    if (chosen != null && mounted) await _react(comment, chosen);
  }

  Widget _commentTile(PostComment c, {required bool reply}) {
    final mine = _me == c.authorId;
    final my = c.reactionOf(_me);
    final muted = TextStyle(
      color: BioTheme.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );
    final summary = [...c.reactionSummary]
      ..sort((a, b) => b.count.compareTo(a.count));
    return Builder(
      builder: (tile) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () => _showPicker(tile, c),
        child: Padding(
          padding: EdgeInsets.fromLTRB(reply ? 42 : 0, 10, 0, 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => openProfile(context, c.authorId),
                child: UserAvatar(
                  name: c.authorName,
                  url: c.avatar,
                  size: reply ? 26 : 32,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: c.authorName,
                            style: const TextStyle(
                              color: BioTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          TextSpan(
                            text: '   ${timeAgo(c.date)}',
                            style: const TextStyle(
                              color: BioTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    MentionText(c.text, onMention: _openMention),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _TinyLink(
                          label: 'Responder',
                          style: muted,
                          onTap: () => _startReply(c),
                        ),
                        _TinyLink(
                          label: my == null
                              ? 'Reaccionar'
                              : '${reactionEmoji(my)} ${reactionLabel(my)}',
                          style: my == null
                              ? muted
                              : muted.copyWith(color: BioTheme.lime),
                          semantics: 'Elegir una reacción para el comentario',
                          onTap: () => _showPicker(tile, c),
                        ),
                        if (summary.isNotEmpty)
                          _TinyLink(
                            label: summary
                                .take(3)
                                .map((r) => reactionEmoji(r.emoji))
                                .join(),
                            style: const TextStyle(fontSize: 13),
                            onTap: () => _showPicker(tile, c),
                          ),
                        _TinyLink(
                          label: '•••',
                          style: muted.copyWith(letterSpacing: 1),
                          semantics: mine
                              ? 'Más opciones de tu comentario'
                              : 'Más opciones del comentario',
                          onTap: () => _options(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _HeartButton(
                reaction: my,
                count: c.reactions,
                busy: _busy.contains(c.id),
                onTap: () => _react(c, my ?? 'LOVE'),
                onLongPress: () => _showPicker(tile, c),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replies(PostComment root) {
    final replies = _repliesOf(root.id);
    if (replies.isEmpty) return const SizedBox.shrink();
    final open = _openReplies.contains(root.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(
              () => open
                  ? _openReplies.remove(root.id)
                  : _openReplies.add(root.id),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(42, 6, 8, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 1, color: BioTheme.textMuted),
                  const SizedBox(width: 10),
                  Text(
                    open
                        ? 'Ocultar respuestas'
                        : 'Ver ${replies.length} ${replies.length == 1 ? 'respuesta' : 'respuestas'}',
                    style: const TextStyle(
                      color: BioTheme.textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: BioTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: open
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in replies) _commentTile(r, reply: true),
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  /// Personas presentes en la publicación: el autor y quienes comentaron.
  List<MentionUser> get _present => [
    MentionUser(
      id: widget.post.authorId,
      username: widget.post.authorName,
      avatar: widget.post.avatar,
    ),
    for (final c in _comments)
      MentionUser(id: c.authorId, username: c.authorName, avatar: c.avatar),
  ];

  void _openMention(String username) =>
      openMention(context, username, known: _present);

  Widget _composer() {
    final user = AppScope.watch(context).user;
    final hasText = _text.text.trim().isNotEmpty;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _replyTo == null && _editing == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  decoration: BoxDecoration(
                    color: BioTheme.lime.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _editing != null
                            ? Icons.edit_outlined
                            : Icons.reply_rounded,
                        size: 16,
                        color: BioTheme.lime,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _editing != null
                              ? 'Editando tu comentario'
                              : 'Respondiendo a @$_replyName',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BioTheme.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cancelar',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: _clearTarget,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
        ),
        MentionSuggestions(controller: _text, present: _present),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: UserAvatar(
                name: user?.username ?? '',
                url: user?.profilePictureUrl,
                size: 32,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _text,
                focusNode: _focus,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                maxLength: 5000,
                buildCounter: (
                  _, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  fontSize: 14,
                  color: BioTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _replyTo != null
                      ? 'Responde a @$_replyName…'
                      : 'Agrega un comentario…',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  border: border,
                  enabledBorder: border,
                  disabledBorder: border,
                  focusedBorder: border.copyWith(
                    borderSide: const BorderSide(color: BioTheme.lime),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              height: 44,
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: hasText ? _send : null,
                      child: Text(
                        _editing != null ? 'Guardar' : 'Publicar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: hasText
                              ? BioTheme.lime
                              : BioTheme.lime.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roots = _roots;
    final hidden = math.max(0, roots.length - _visibleRoots);
    final shown = roots.sublist(hidden);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          if (_loading && _comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 18,
                    color: BioTheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      messageFor(_error!),
                      style: const TextStyle(
                        color: BioTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(onPressed: _load, child: const Text('Reintentar')),
                ],
              ),
            ),
          if (!_loading && _error == null && roots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Text(
                    'Aún no hay comentarios',
                    style: TextStyle(
                      color: BioTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sé la primera persona en comentar.',
                    style: TextStyle(color: BioTheme.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          if (hidden > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _visibleRoots += 10),
                child: Text(
                  hidden == 1
                      ? 'Ver 1 comentario anterior'
                      : 'Ver $hidden comentarios anteriores',
                  style: const TextStyle(color: BioTheme.textSecondary),
                ),
              ),
            ),
          for (final root in shown) ...[
            _commentTile(root, reply: false),
            _replies(root),
          ],
          const SizedBox(height: 12),
          _composer(),
        ],
      ),
    );
  }
}

class _TinyLink extends StatelessWidget {
  const _TinyLink({
    required this.label,
    required this.style,
    required this.onTap,
    this.semantics,
  });
  final String label;
  final TextStyle style;
  final VoidCallback onTap;
  final String? semantics;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semantics,
    child: InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 16, 6),
        child: Text(label, style: style),
      ),
    ),
  );
}

/// Abre el perfil de una persona mencionada (@usuario). [known] evita
/// consultar al servidor cuando ya se sabe quién es.
Future<void> openMention(
  BuildContext context,
  String username, {
  List<MentionUser> known = const [],
}) async {
  final match = known.where(
    (u) => u.username.toLowerCase() == username.toLowerCase(),
  );
  if (match.isNotEmpty) return openProfile(context, match.first.id);
  try {
    final id = await AppScope.read(context).community
        .userIdByUsername(username);
    if (!context.mounted) return;
    if (id == null) {
      showMessage(context, 'No encontramos a @$username.');
    } else {
      openProfile(context, id);
    }
  } catch (e) {
    if (context.mounted) showMessage(context, messageFor(e));
  }
}

String _plainText(String v) => v
    .toLowerCase()
    .replaceAll(RegExp('[áàä]'), 'a')
    .replaceAll(RegExp('[éèë]'), 'e')
    .replaceAll(RegExp('[íìï]'), 'i')
    .replaceAll(RegExp('[óòö]'), 'o')
    .replaceAll(RegExp('[úùü]'), 'u');

/// Lista de personas para completar una mención mientras se escribe "@" en
/// [controller] (comentarios, título o descripción de una publicación).
class MentionSuggestions extends StatefulWidget {
  const MentionSuggestions({
    super.key,
    required this.controller,
    this.present = const [],
  });
  final TextEditingController controller;

  /// Personas que se sugieren primero (p. ej. quienes comentaron).
  final List<MentionUser> present;
  @override
  State<MentionSuggestions> createState() => _MentionSuggestionsState();
}

class _MentionSuggestionsState extends State<MentionSuggestions> {
  static final _atCursor = RegExp(r'(?:^|\s)@([\wÀ-ÿ.]*)$');
  List<MentionUser> _people = const [];
  bool _requested = false;
  String? _query;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(MentionSuggestions old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final value = widget.controller.value;
    final cursor = value.selection.baseOffset;
    final before = cursor < 0 || cursor > value.text.length
        ? value.text
        : value.text.substring(0, cursor);
    final query = _atCursor.firstMatch(before)?.group(1);
    if (query != _query) setState(() => _query = query);
    if (query != null && !_requested) {
      _requested = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final people = await AppScope.read(context).community.mentionCandidates();
      if (mounted) setState(() => _people = people);
    } catch (_) {
      // Sin la lista se sugiere a quienes ya participan.
    }
  }

  List<MentionUser> get _matches {
    final query = _query;
    if (query == null) return const [];
    final q = _plainText(query);
    final me = AppScope.read(context).user?.id;
    final seen = <String>{};
    final result = <MentionUser>[];
    for (final u in [...widget.present, ..._people]) {
      if (u.id == me || !seen.add(u.id)) continue;
      if (q.isEmpty ||
          _plainText(u.username).contains(q) ||
          _plainText(u.name).contains(q)) {
        result.add(u);
      }
      if (result.length == 6) break;
    }
    return result;
  }

  void _pick(MentionUser user) {
    final controller = widget.controller;
    final text = controller.text;
    final cursor = controller.selection.baseOffset < 0
        ? text.length
        : controller.selection.baseOffset;
    final before = text.substring(0, cursor);
    final start = before.lastIndexOf('@');
    final inserted = '${before.substring(0, start)}@${user.username} ';
    controller.value = TextEditingValue(
      text: inserted + text.substring(cursor),
      selection: TextSelection.collapsed(offset: inserted.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _matches;
    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      child: items.isEmpty
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: BioTheme.backgroundDeep.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 18),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final u in items)
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _pick(u),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              name: u.username,
                              url: u.avatar,
                              size: 34,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u.username,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: BioTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (u.name.isNotEmpty)
                                    Text(
                                      u.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: BioTheme.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

/// Texto que resalta las menciones (@usuario) como en Instagram; al tocarlas
/// se llama a [onMention] con el usuario.
class MentionText extends StatefulWidget {
  const MentionText(
    this.text, {
    super.key,
    required this.onMention,
    this.style = const TextStyle(
      color: BioTheme.textPrimary,
      fontSize: 14,
      height: 1.35,
    ),
    this.maxLines,
    this.overflow,
  });
  final String text;
  final ValueChanged<String> onMention;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  @override
  State<MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<MentionText> {
  static final _pattern = RegExp(r'@([\wÀ-ÿ.]+)');
  final _recognizers = <TapGestureRecognizer>[];

  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final text = widget.text;
    final spans = <TextSpan>[];
    var last = 0;
    for (final m in _pattern.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      // Un punto final no es parte del usuario ("gracias @ana.").
      var name = m.group(1)!;
      var end = m.end;
      while (name.endsWith('.')) {
        name = name.substring(0, name.length - 1);
        end--;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onMention(name);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: '@$name',
          recognizer: recognizer,
          style: const TextStyle(
            color: BioTheme.lime,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
      last = end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({
    required this.reaction,
    required this.count,
    required this.busy,
    required this.onTap,
    required this.onLongPress,
  });
  final String? reaction;
  final int count;
  final bool busy;
  final VoidCallback onTap, onLongPress;

  @override
  Widget build(BuildContext context) {
    final Widget icon = switch (reaction) {
      null => const Icon(
        Icons.favorite_border_rounded,
        key: ValueKey('none'),
        size: 18,
        color: BioTheme.textSecondary,
      ),
      'LOVE' => const Icon(
        Icons.favorite_rounded,
        key: ValueKey('LOVE'),
        size: 18,
        color: loveColor,
      ),
      final String code => Text(
        reactionEmoji(code),
        key: ValueKey(code),
        style: const TextStyle(fontSize: 16),
      ),
    };
    return Semantics(
      button: true,
      label: reaction == null
          ? 'Reaccionar al comentario'
          : 'Retirar tu reacción',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: busy ? null : onTap,
        onLongPress: busy ? null : onLongPress,
        child: SizedBox(
          width: 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                    child: child,
                  ),
                  child: icon,
                ),
                if (count > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: BioTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Barra flotante de reacciones que aparece al mantener presionado.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.anchor, required this.current});
  final Rect anchor;
  final String? current;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    const height = 58.0;
    var top = anchor.top - height - 6;
    if (top < media.padding.top + 8) top = anchor.bottom + 6;
    top = math.min(top, media.size.height - media.padding.bottom - height - 8);
    return Stack(
      children: [
        Positioned(
          top: top,
          left: 16,
          right: 16,
          child: Center(
            child: Material(
              color: BioTheme.backgroundDeep,
              elevation: 10,
              shadowColor: Colors.black54,
              shape: StadiumBorder(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < commentReactions.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 200 + i * 45),
                        curve: Curves.easeOutBack,
                        builder: (_, value, child) =>
                            Transform.scale(scale: value, child: child),
                        child: Tooltip(
                          message: commentReactions[i].$3,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                Navigator.pop(context, commentReactions[i].$1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: current == commentReactions[i].$1
                                    ? BioTheme.lime.withValues(alpha: 0.25)
                                    : Colors.transparent,
                              ),
                              child: Text(
                                commentReactions[i].$2,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
