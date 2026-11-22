import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/community_repository.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/post_comments.dart' show UserAvatar;
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'post_editor_screen.dart';
import '../widgets/post_card.dart';

export '../widgets/post_card.dart';

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
        icon: const Icon(Icons.add_box_outlined, color: BioTheme.lime),
      ),
    ],
    body: RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ComposerBar(onTap: _compose),
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
            const _FeedEnd(),
        ],
      ),
    ),
  );
}

/// Acceso rápido para publicar, en lugar de los bloques que ocupaban el inicio.
class _ComposerBar extends StatelessWidget {
  const _ComposerBar({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final user = AppScope.watch(context).user;
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              UserAvatar(
                name: user?.username ?? '',
                url: user?.profilePictureUrl,
                size: 40,
                ring: true,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '¿Qué descubriste hoy en el campus?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: BioTheme.textMuted, fontSize: 14.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BioTheme.lime.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: BioTheme.lime,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedEnd extends StatelessWidget {
  const _FeedEnd();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(24, 20, 24, 32),
    child: Column(
      children: [
        Icon(Icons.check_circle_outline_rounded, color: BioTheme.lime, size: 40),
        SizedBox(height: 10),
        Text(
          'Estás al día',
          style: TextStyle(
            color: BioTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Ya viste todas las publicaciones de la comunidad.',
          textAlign: TextAlign.center,
          style: TextStyle(color: BioTheme.textMuted, fontSize: 13),
        ),
      ],
    ),
  );
}
