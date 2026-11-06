import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_repository.dart';
import '../state/app_scope.dart';
import '../navigation/app_routes.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'post_editor_screen.dart';
import 'post_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final List<CommunityPost> _posts = [];
  String? _cursor;
  Object? _error;
  bool _loading = false, _loaded = false;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadMore() {
    if (_scroll.position.extentAfter < 500 &&
        _cursor != null &&
        _error == null) {
      _load();
    }
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await AppScope.read(
        context,
      ).community.feed(cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _posts.clear();
        final ids = _posts.map((p) => p.id).toSet();
        _posts.addAll(page.items.where((p) => ids.add(p.id)));
        _cursor = page.nextCursor;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _compose() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostEditorScreen()),
    );
    if (saved == true && mounted) _load(reset: true);
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'BioJaveriana',
    tab: BioTab.home,
    actions: [
      IconButton(
        tooltip: 'Crear publicación',
        onPressed: _compose,
        icon: const Icon(Icons.add_box_outlined),
      ),
    ],
    body: RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BioPageHeading(
                  eyebrow: 'Biodiversidad javeriana',
                  title: 'La vida del campus',
                  accent: 'se comparte.',
                  description:
                      'Descubrimientos, fotografías e historias de nuestra comunidad.',
                ),
                BioGlassAction(
                  title: 'Comparte lo que descubriste',
                  subtitle: 'Una fotografía. Una historia. Tu campus.',
                  icon: Icons.edit_outlined,
                  onTap: _compose,
                ),
                BioGlassAction(
                  title: 'Biodiversidad del campus',
                  subtitle:
                      'Conoce las especies que comparten este espacio contigo.',
                  icon: Icons.eco_outlined,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.explore),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 22, 24, 12),
            child: Text(
              'NUESTRA COMUNIDAD',
              style: TextStyle(fontSize: 11, letterSpacing: 2),
            ),
          ),
          for (final post in _posts)
            PostCard(post: post, onChanged: () => _load(reset: true)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            StatusPanel(
              title: _error is FeatureUnavailable
                  ? 'La comunidad está por llegar'
                  : 'No pudimos cargar el inicio',
              message: _error is FeatureUnavailable
                  ? 'Aquí verás las publicaciones de la comunidad. Puedes explorar el editor; publicar estará disponible cuando se habilite el servicio.'
                  : messageFor(_error!),
              icon: Icons.people_outline,
              action: () => _load(reset: _posts.isEmpty),
            ),
          if (_loaded && _posts.isEmpty && !_loading && _error == null)
            const StatusPanel(
              title: 'Todavía no hay publicaciones',
              message: 'Comparte el primer descubrimiento de la comunidad.',
            ),
          if (_loaded && _posts.isNotEmpty && _cursor == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('Estás al día con la comunidad')),
            ),
        ],
      ),
    ),
  );
}

class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post, required this.onChanged});
  final CommunityPost post;
  final VoidCallback onChanged;
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _busy = false;
  late CommunityPost _post = widget.post;
  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post;
  }

  Future<void> _like() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final post = await AppScope.read(
        context,
      ).community.like(_post.id, !_post.liked);
      if (mounted) setState(() => _post = post);
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
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

  @override
  Widget build(BuildContext context) {
    final mine = AppScope.watch(context).user?.id == _post.authorId;
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: _post.avatar != null
                ? ClipOval(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: RemotePhoto(_post.avatar!, height: 40),
                    ),
                  )
                : CircleAvatar(
                    child: Text(
                      _post.authorName.isEmpty
                          ? '?'
                          : _post.authorName.substring(0, 1).toUpperCase(),
                    ),
                  ),
            title: Text(_post.authorName),
            subtitle: Text(dateLabel(_post.date.toLocal())),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: _post.authorId),
              ),
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Opciones de publicación',
              onSelected: _menu,
              itemBuilder: (_) => [
                if (mine)
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                if (mine)
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                if (!mine)
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Denunciar'),
                  ),
              ],
            ),
          ),
          if (_post.images.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView(
                children: [
                  for (var i = 0; i < _post.images.length; i++)
                    Stack(
                      children: [
                        RemotePhoto(_post.images[i], height: 300),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Chip(
                            label: Text('${i + 1}/${_post.images.length}'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _post.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_post.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_post.text),
                  ),
                if (_post.sighting != null)
                  Chip(
                    avatar: const Icon(Icons.eco_outlined),
                    label: Text(
                      '${_post.sighting!.species} · ${_post.sighting!.status.label}',
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: _busy ? null : _like,
                      icon: Icon(
                        _post.liked ? Icons.favorite : Icons.favorite_border,
                      ),
                      label: Text('${_post.likes} Me gusta'),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailScreen(post: _post),
                          ),
                        );
                        if (mounted) widget.onChanged();
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text('${_post.comments} comentarios'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
