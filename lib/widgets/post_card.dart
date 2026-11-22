import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/community.dart';
import '../screens/post_detail_screen.dart' show reportContent;
import '../screens/post_editor_screen.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import 'community_widgets.dart';
import 'post_comments.dart';

/// Publicación de la comunidad con comentarios desplegables en la misma
/// tarjeta, al estilo de Instagram.
class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onChanged,
    this.initiallyShowComments = false,
  });
  final CommunityPost post;

  /// Se llama tras editar o eliminar la publicación.
  final VoidCallback onChanged;
  final bool initiallyShowComments;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late CommunityPost _post = widget.post;
  late bool _showComments = widget.initiallyShowComments;
  late bool _commentsBuilt = widget.initiallyShowComments;
  bool _busy = false, _fullText = false;
  int _page = 0;
  final _commentFocus = FocusNode();
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) _post = widget.post;
  }

  @override
  void dispose() {
    _commentFocus.dispose();
    _burst.dispose();
    super.dispose();
  }

  CommunityPost _optimistic(CommunityPost p, String? next) {
    final likes = p.likes - (p.liked ? 1 : 0) + (next == 'LIKE' ? 1 : 0);
    final dislikes =
        p.dislikes - (p.disliked ? 1 : 0) + (next == 'DISLIKE' ? 1 : 0);
    return p.copyWith(
      likes: math.max(0, likes),
      dislikes: math.max(0, dislikes),
      liked: next == 'LIKE',
      disliked: next == 'DISLIKE',
    );
  }

  Future<void> _vote(String type) async {
    if (_busy) return;
    final before = _post;
    final already = type == 'LIKE' ? before.liked : before.disliked;
    final next = already ? null : type;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _post = _optimistic(before, next);
    });
    try {
      final server = await AppScope.read(
        context,
      ).community.vote(before.id, next);
      if (mounted) {
        setState(
          () => _post = _post.copyWith(
            likes: server.likes,
            dislikes: server.dislikes,
            liked: server.liked,
            disliked: server.disliked,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _post = before);
        showMessage(context, messageFor(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _doubleTapLike() {
    HapticFeedback.lightImpact();
    _burst.forward(from: 0);
    if (!_post.liked) _vote('LIKE');
  }

  void _toggleComments({bool focus = false}) {
    setState(() {
      _commentsBuilt = true;
      _showComments = focus || !_showComments;
    });
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => Future.delayed(const Duration(milliseconds: 260), () {
          if (mounted && _showComments) _commentFocus.requestFocus();
        }),
      );
    }
  }

  Future<void> _menu(String action) async {
    final repo = AppScope.read(context).community;
    if (action == 'report') {
      await reportContent(context, _post.id, comment: false);
      return;
    }
    if (action == 'edit') {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PostEditorScreen(post: _post)),
      );
      if (result == true) widget.onChanged();
      return;
    }
    if (!await confirmAction(
      context,
      'Eliminar publicación',
      'Se eliminará la publicación y no podrás recuperarla.',
    )) {
      return;
    }
    try {
      await repo.deletePost(_post.id);
      if (mounted) widget.onChanged();
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    }
  }

  Widget _header(bool mine) {
    final sighting = _post.sighting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => openProfile(context, _post.authorId),
            child: UserAvatar(
              name: _post.authorName,
              url: _post.avatar,
              size: 38,
              ring: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => openProfile(context, _post.authorId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _post.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BioTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  Text(
                    sighting == null
                        ? timeAgo(_post.date)
                        : '${timeAgo(_post.date)} · ${sighting.species}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: BioTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Opciones de publicación',
            icon: const Icon(
              Icons.more_horiz_rounded,
              color: BioTheme.textSecondary,
            ),
            onSelected: _menu,
            itemBuilder: (_) => [
              if (mine)
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
              if (mine)
                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              if (!mine)
                const PopupMenuItem(value: 'report', child: Text('Denunciar')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gallery() {
    final images = _post.images;
    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      child: SizedBox(
        height: 340,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => RemotePhoto(images[i], height: 340),
            ),
            if (images.length > 1)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_page + 1}/${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < images.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == _page
                              ? BioTheme.lime
                              : Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            IgnorePointer(
              child: Center(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (_, _) {
                    final t = _burst.value;
                    if (t == 0 || _burst.isCompleted) {
                      return const SizedBox.shrink();
                    }
                    final scale = t < 0.3
                        ? Curves.easeOutBack.transform(t / 0.3)
                        : 1.0;
                    final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
                    return Opacity(
                      opacity: math.max(0.0, math.min(1.0, opacity)),
                      child: Transform.scale(
                        scale: scale,
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 104,
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 24, color: Colors.black45),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    final sighting = _post.sighting;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 0),
      child: Row(
        children: [
          _ActionIcon(
            tooltip: _post.liked ? 'Quitar me gusta' : 'Me gusta',
            icon: _post.liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: _post.liked ? loveColor : BioTheme.textPrimary,
            onTap: () => _vote('LIKE'),
          ),
          _ActionIcon(
            tooltip: _post.disliked ? 'Quitar no me gusta' : 'No me gusta',
            icon: _post.disliked
                ? Icons.thumb_down_alt_rounded
                : Icons.thumb_down_alt_outlined,
            color: _post.disliked ? BioTheme.lime : BioTheme.textPrimary,
            onTap: () => _vote('DISLIKE'),
          ),
          _ActionIcon(
            tooltip: 'Comentar',
            icon: Icons.mode_comment_outlined,
            color: BioTheme.textPrimary,
            onTap: () => _toggleComments(focus: true),
          ),
          const Spacer(),
          if (sighting != null)
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: BioTheme.lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.eco_outlined,
                      size: 14,
                      color: BioTheme.lime,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        sighting.status.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BioTheme.lime,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _caption() {
    final long = _post.text.length > 140 || '\n'.allMatches(_post.text).length > 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _post.likes == 1 ? '1 Me gusta' : '${_post.likes} Me gusta',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_post.dislikes > 0)
                  TextSpan(
                    text: '  ·  ${_post.dislikes} No me gusta',
                    style: const TextStyle(color: BioTheme.textMuted),
                  ),
              ],
            ),
            style: const TextStyle(color: BioTheme.textPrimary, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          Text(
            _post.title,
            style: const TextStyle(
              color: BioTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (_post.text.isNotEmpty)
            GestureDetector(
              onTap: long ? () => setState(() => _fullText = !_fullText) : null,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _post.text,
                        maxLines: _fullText ? null : 3,
                        overflow: _fullText
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BioTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      if (long)
                        Text(
                          _fullText ? 'menos' : 'más',
                          style: const TextStyle(
                            color: BioTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _commentsToggle() {
    final n = _post.comments;
    final label = _showComments
        ? 'Ocultar comentarios'
        : n == 0
        ? 'Agrega el primer comentario'
        : n == 1
        ? 'Ver 1 comentario'
        : 'Ver los $n comentarios';
    return InkWell(
      onTap: _toggleComments,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
        child: Row(
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: BioTheme.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _showComments ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: BioTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mine = AppScope.watch(context).user?.id == _post.authorId;
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(mine),
          if (_post.images.isNotEmpty) _gallery(),
          _actions(),
          _caption(),
          _commentsToggle(),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _commentsBuilt
                ? Visibility(
                    visible: _showComments,
                    maintainState: true,
                    child: PostCommentsSection(
                      post: _post,
                      focusNode: _commentFocus,
                      onCountChanged: (n) {
                        if (mounted && n != _post.comments) {
                          setState(() => _post = _post.copyWith(comments: n));
                        }
                      },
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    icon: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
      child: Icon(icon, key: ValueKey(icon), color: color, size: 26),
    ),
  );
}

/// Réplica estática de [PostCard] para mostrar la publicación antes de
/// enviarla. Las fotos llegan como widgets para admitir imágenes locales.
class PostPreviewCard extends StatefulWidget {
  const PostPreviewCard({
    super.key,
    required this.authorName,
    required this.title,
    required this.text,
    required this.images,
    this.avatar,
    this.sighting,
  });
  final String authorName, title, text;
  final String? avatar;
  final List<Widget> images;
  final Sighting? sighting;
  @override
  State<PostPreviewCard> createState() => _PostPreviewCardState();
}

class _PostPreviewCardState extends State<PostPreviewCard> {
  int _page = 0;

  @override
  void didUpdateWidget(PostPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_page >= widget.images.length) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final sighting = widget.sighting;
    final images = widget.images;
    const placeholder = TextStyle(
      color: BioTheme.textMuted,
      fontStyle: FontStyle.italic,
    );
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 10),
            child: Row(
              children: [
                UserAvatar(
                  name: widget.authorName,
                  url: widget.avatar,
                  size: 38,
                  ring: true,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.authorName,
                        style: const TextStyle(
                          color: BioTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        sighting == null ? 'ahora' : 'ahora · ${sighting.species}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  color: BioTheme.textSecondary,
                ),
              ],
            ),
          ),
          if (images.isNotEmpty)
            SizedBox(
              height: 340,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView(
                    onPageChanged: (i) => setState(() => _page = i),
                    children: images,
                  ),
                  if (images.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_page + 1}/${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (images.length > 1)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < images.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _page ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: i == _page
                                    ? BioTheme.lime
                                    : Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_border_rounded,
                  color: BioTheme.textPrimary,
                  size: 26,
                ),
                const SizedBox(width: 22),
                const Icon(
                  Icons.thumb_down_alt_outlined,
                  color: BioTheme.textPrimary,
                  size: 26,
                ),
                const SizedBox(width: 22),
                const Icon(
                  Icons.mode_comment_outlined,
                  color: BioTheme.textPrimary,
                  size: 26,
                ),
                const Spacer(),
                if (sighting != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: BioTheme.lime.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        sighting.status.label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BioTheme.lime,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '0 Me gusta',
                  style: TextStyle(
                    color: BioTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title.isEmpty
                      ? 'Tu título aparecerá aquí'
                      : widget.title,
                  style: widget.title.isEmpty
                      ? placeholder.copyWith(fontSize: 16)
                      : const TextStyle(
                          color: BioTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.text.isEmpty
                      ? 'Y aquí la descripción de lo que descubriste.'
                      : widget.text,
                  style: widget.text.isEmpty
                      ? placeholder.copyWith(fontSize: 14)
                      : const TextStyle(
                          color: BioTheme.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Text(
              'Agrega el primer comentario',
              style: TextStyle(
                color: BioTheme.textMuted,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
