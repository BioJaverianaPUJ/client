import 'package:flutter/material.dart';
import 'reports_screen.dart';
import 'account_screen.dart';
import 'post_detail_screen.dart';
import 'post_editor_screen.dart';
import '../theme/bio_theme.dart';
import '../models/user_profile.dart';
import '../models/community.dart';
import '../models/experience.dart';
import '../models/gender.dart';
import '../navigation/app_routes.dart';
import '../services/photo_service.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import '../widgets/post_comments.dart' show UserAvatar;
import '../widgets/level_badge.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});
  final String? userId;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  Object? _error;
  bool _busy = false;

  ProgressSummary? _progress;
  Object? _progressError;
  bool _progressLoading = true;

  final List<CommunityPost> _posts = [];
  String? _cursor;
  int? _postTotal;
  Object? _postsError;
  bool _postsLoading = false;

  bool get _own =>
      widget.userId == null || widget.userId == AppScope.read(context).user?.id;

  String? get _userId =>
      widget.userId ?? _user?.id ?? AppScope.read(context).user?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    await _load();
    if (!mounted) return;
    await Future.wait([_loadProgress(), _loadPosts(reset: true)]);
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = AppScope.read(context);
      final user = _own
          ? await session.users.me()
          : await session.users.byId(widget.userId!);
      if (mounted) setState(() => _user = user);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadProgress() async {
    final id = _userId;
    if (id == null) return;
    setState(() {
      _progressLoading = true;
      _progressError = null;
    });
    try {
      final progress = await AppScope.read(
        context,
      ).community.progress(userId: id);
      if (mounted) setState(() => _progress = progress);
    } catch (e) {
      if (mounted) setState(() => _progressError = e);
    } finally {
      if (mounted) setState(() => _progressLoading = false);
    }
  }

  Future<void> _loadPosts({bool reset = false}) async {
    final id = _userId;
    if (id == null || _postsLoading) return;
    setState(() {
      _postsLoading = true;
      _postsError = null;
    });
    try {
      final page = await AppScope.read(
        context,
      ).community.feed(authorId: id, cursor: reset ? null : _cursor);
      if (!mounted) return;
      setState(() {
        if (reset) _posts.clear();
        final ids = _posts.map((p) => p.id).toSet();
        _posts.addAll(page.items.where((p) => ids.add(p.id)));
        _cursor = page.nextCursor;
        _postTotal = page.total;
      });
    } catch (e) {
      if (mounted) setState(() => _postsError = e);
    } finally {
      if (mounted) setState(() => _postsLoading = false);
    }
  }

  Future<void> _media(String type, {bool remove = false}) async {
    final users = AppScope.read(context).users;
    if (remove &&
        !await confirmAction(
          context,
          'Eliminar imagen',
          'Se eliminará esta imagen de tu perfil.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      UserProfile updated;
      if (remove) {
        updated = await users.removeMedia(type);
      } else {
        final photos = await PhotoService().pick(camera: false);
        if (photos.isEmpty) return;
        updated = await users.upload(photos.single, type);
      }
      if (mounted) {
        setState(() => _user = updated);
        await AppScope.read(context).reloadProfile();
      }
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mediaMenu(String type, bool hasImage) async {
    final banner = type == 'banner';
    final action = await _sheet([
      (
        'change',
        Icons.photo_library_outlined,
        banner ? 'Cambiar banner' : 'Cambiar foto',
        false,
      ),
      if (hasImage)
        (
          'remove',
          Icons.delete_outline,
          banner ? 'Eliminar banner' : 'Eliminar foto',
          true,
        ),
    ]);
    if (action == null || !mounted) return;
    await _media(type, remove: action == 'remove');
  }

  Future<String?> _sheet(List<(String, IconData, String, bool)> items) =>
      showModalBottomSheet<String>(
        context: context,
        backgroundColor: BioTheme.backgroundDeep,
        showDragHandle: true,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (value, icon, label, danger) in items)
                ListTile(
                  leading: Icon(
                    icon,
                    color: danger ? BioTheme.danger : BioTheme.textPrimary,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      color: danger ? BioTheme.danger : BioTheme.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheet, value),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

  Future<void> _settings() async {
    final action = await _sheet([
      ('records', Icons.eco_outlined, 'Mis observaciones', false),
      ('missions', Icons.emoji_events_outlined, 'Misiones y logros', false),
      ('catalog', Icons.menu_book_outlined, 'Catálogo de especies', false),
      ('reports', Icons.flag_outlined, 'Mis denuncias', false),
      ('password', Icons.lock_outline, 'Cambiar contraseña', false),
      ('delete', Icons.person_remove_outlined, 'Eliminar mi cuenta', false),
      ('logout', Icons.logout, 'Cerrar sesión', true),
    ]);
    if (!mounted || action == null) return;
    switch (action) {
      case 'records':
        Navigator.pushNamed(context, AppRoutes.records);
      case 'missions':
        AppRoutes.goTo(context, AppRoutes.gamification);
      case 'catalog':
        Navigator.pushNamed(context, AppRoutes.explore);
      case 'reports':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsScreen()),
        );
      case 'password':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
      case 'delete':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen(delete: true)),
        );
      case 'logout':
        await AppRoutes.logout(context);
    }
  }

  Future<void> _openPost(CommunityPost post) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
    );
    if (mounted) await _loadPosts(reset: true);
  }

  Future<void> _compose() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PostEditorScreen()),
    );
    if (saved == true && mounted) await _loadPosts(reset: true);
  }

  Widget _header(UserProfile user) {
    final banner = user.bannerUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 222,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                height: 170,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      banner == null
                          ? const _DefaultBanner()
                          : RemotePhoto(
                              banner,
                              height: 170,
                              fallback: const _DefaultBanner(),
                            ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x66002E29)],
                          ),
                        ),
                      ),
                      if (_own)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _RoundIcon(
                            tooltip: 'Cambiar banner',
                            icon: Icons.photo_camera_outlined,
                            onTap: _busy
                                ? null
                                : () => _mediaMenu('banner', banner != null),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 28,
                bottom: 0,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: BioTheme.background,
                      ),
                      child: UserAvatar(
                        name: user.username,
                        url: user.profilePictureUrl,
                        size: 90,
                        ring: true,
                      ),
                    ),
                    if (_own)
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: _RoundIcon(
                          tooltip: 'Cambiar foto de perfil',
                          icon: Icons.photo_camera_outlined,
                          primary: true,
                          size: 34,
                          onTap: _busy
                              ? null
                              : () => _mediaMenu(
                                  'profile-picture',
                                  user.profilePictureUrl != null,
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _own ? user.fullName : user.username,
                style: const TextStyle(
                  color: BioTheme.textPrimary,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@${user.username}',
                style: const TextStyle(
                  color: BioTheme.textMuted,
                  fontSize: 14,
                ),
              ),
              if (_own) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy
                            ? null
                            : () async {
                                final saved = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfileScreen(user: user),
                                  ),
                                );
                                if (saved == true && mounted) await _load();
                              },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Editar perfil'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.records),
                        icon: const Icon(Icons.eco_outlined, size: 18),
                        label: const Text('Observaciones'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats() {
    final progress = _progress;
    final experience = progress == null ? null : Experience(progress.xp);
    final posts = _postTotal ?? _posts.length;
    return BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Stat(
                value: _postsLoading && _posts.isEmpty ? '…' : '$posts',
                label: posts == 1 ? 'Publicación' : 'Publicaciones',
              ),
              const _StatDivider(),
              _Stat(
                value: progress == null ? '—' : '${progress.level}',
                label: 'Nivel',
              ),
              const _StatDivider(),
              _Stat(value: progress == null ? '—' : '${progress.xp}', label: 'XP'),
            ],
          ),
          if (_own) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 14),
            const Text(
              'TU EXPERIENCIA',
              style: TextStyle(
                letterSpacing: 2,
                fontSize: 11,
                color: BioTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            if (_progressLoading)
              const LinearProgressIndicator()
            else if (progress != null && experience != null) ...[
              Row(
                children: [
                  LevelBadge(level: progress.level, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nivel ${progress.level} · ${experience.xp} XP',
                          style: const TextStyle(
                            color: BioTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15.5,
                          ),
                        ),
                        Text(
                          'Insignia ${badgeName(progress.level)}',
                          style: const TextStyle(
                            color: BioTheme.lime,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.levelProgress ?? experience.fraction,
                  minHeight: 8,
                  color: BioTheme.lime,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  semanticsLabel: 'Progreso al siguiente nivel',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${((progress.nextLevelXp ?? experience.nextThreshold) - experience.xp).clamp(0, 2147483647)} XP para el siguiente nivel',
                style: const TextStyle(
                  color: BioTheme.textMuted,
                  fontSize: 12.5,
                ),
              ),
              if (progress.achievements.any((a) => a.completed)) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final a in progress.achievements.where(
                      (a) => a.completed,
                    ))
                      Chip(
                        avatar: const Icon(
                          Icons.emoji_events_outlined,
                          size: 16,
                          color: BioTheme.lime,
                        ),
                        label: Text(a.title),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ] else
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tu experiencia aparecerá cuando el servicio esté disponible.',
                      style: TextStyle(
                        color: BioTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadProgress,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _postsHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(
      children: [
        const Icon(Icons.grid_on_rounded, color: BioTheme.lime, size: 20),
        const SizedBox(width: 8),
        const Text(
          'Publicaciones',
          style: TextStyle(
            color: BioTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        if (_own)
          TextButton.icon(
            onPressed: _compose,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nueva'),
          ),
      ],
    ),
  );

  Widget _postsState() {
    if (_posts.isNotEmpty) {
      return Column(
        children: [
          if (_postsLoading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_cursor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () => _loadPosts(),
                child: const Text('Ver más publicaciones'),
              ),
            ),
        ],
      );
    }
    if (_postsLoading) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_postsError != null) {
      return StatusPanel(
        title: 'Publicaciones no disponibles',
        message: messageFor(_postsError!),
        icon: Icons.grid_off_rounded,
        action: () => _loadPosts(reset: true),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BioTheme.lime.withValues(alpha: 0.5)),
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              color: BioTheme.lime,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _own ? 'Aún no has publicado' : 'Aún no hay publicaciones',
            style: const TextStyle(
              color: BioTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          if (_own) ...[
            const SizedBox(height: 4),
            const Text(
              'Comparte tu primer descubrimiento del campus.',
              textAlign: TextAlign.center,
              style: TextStyle(color: BioTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _compose,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Crear publicación'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? (_own ? AppScope.watch(context).user : null);
    return CommunityScaffold(
      title: _own
          ? 'Mi perfil'
          : user == null
          ? 'Perfil'
          : '@${user.username}',
      tab: widget.userId == null ? BioTab.profile : null,
      actions: [
        if (_own)
          IconButton(
            tooltip: 'Configuración',
            onPressed: _settings,
            icon: const Icon(Icons.settings_outlined),
          ),
      ],
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_busy && user == null) const LinearProgressIndicator(),
                  if (_error != null)
                    StatusPanel(
                      title: 'No pudimos cargar el perfil',
                      message: messageFor(_error!),
                      action: _refresh,
                    ),
                  if (user == null && _own && !_busy)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: OutlinedButton.icon(
                        onPressed: () => AppRoutes.logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                      ),
                    ),
                  if (user != null) ...[
                    _header(user),
                    _stats(),
                    _postsHeader(),
                  ],
                ],
              ),
            ),
            if (user != null && _posts.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PostTile(
                      post: _posts[i],
                      onTap: () => _openPost(_posts[i]),
                    ),
                    childCount: _posts.length,
                  ),
                ),
              ),
            if (user != null) SliverToBoxAdapter(child: _postsState()),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: BioTheme.textPrimary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: BioTheme.textMuted, fontSize: 12),
        ),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 34,
    color: Colors.white.withValues(alpha: 0.12),
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.size = 38,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary;
  final double size;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: primary
          ? BioTheme.lime
          : BioTheme.backgroundDeep.withValues(alpha: 0.75),
      shape: CircleBorder(
        side: BorderSide(
          color: primary ? BioTheme.background : Colors.white24,
          width: primary ? 3 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.5,
            color: primary ? BioTheme.iconDark : BioTheme.textPrimary,
          ),
        ),
      ),
    ),
  );
}

/// Miniatura de una publicación en la cuadrícula del perfil.
class _PostTile extends StatelessWidget {
  const _PostTile({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  Widget _textTile() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          BioTheme.lime.withValues(alpha: 0.22),
          BioTheme.forest.withValues(alpha: 0.35),
        ],
      ),
    ),
    alignment: Alignment.center,
    child: Text(
      post.title,
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: BioTheme.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        height: 1.25,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Material(
      color: BioTheme.backgroundDeep,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (post.images.isEmpty)
              _textTile()
            else
              Image.network(
                RemotePhoto.resolve(post.images.first),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _textTile(),
              ),
            if (post.images.length > 1)
              const Positioned(
                top: 6,
                right: 6,
                child: Icon(
                  Icons.collections_rounded,
                  size: 18,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            if (post.likes > 0)
              Positioned(
                left: 6,
                bottom: 5,
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      size: 13,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${post.likes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DefaultBanner extends StatelessWidget {
  const _DefaultBanner();
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [BioTheme.forest, BioTheme.iconDark, BioTheme.backgroundDeep],
      ),
    ),
    child: Align(
      alignment: const Alignment(0.85, 0),
      child: Icon(
        Icons.eco,
        size: 130,
        color: BioTheme.lime.withValues(alpha: 0.14),
      ),
    ),
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});
  final UserProfile user;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.user.firstName);
  late final _last = TextEditingController(text: widget.user.lastName);
  late final _username = TextEditingController(text: widget.user.username);
  late Gender? _gender = widget.user.gender;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = AppScope.read(context);
      await session.users.update({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'username': _username.text.trim(),
        'gender': _gender!.apiValue,
      });
      await session.reloadProfile();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Editar perfil',
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field(_first, 'Nombres', 1, 50),
          _field(_last, 'Apellidos', 1, 50),
          _field(_username, 'Nombre de usuario', 3, 25),
          const Text(
            'Puedes cambiar tu nombre de usuario una vez cada dos semanas.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Género'),
            items: Gender.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                .toList(),
            onChanged: _busy ? null : (v) => setState(() => _gender = v),
            validator: (v) => v == null ? 'Selecciona tu género.' : null,
          ),
          const SizedBox(height: 20),
          const Text(
            'El cambio de correo y contraseña aún no está disponible.',
          ),
          if (_error != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Guardando…' : 'Guardar cambios'),
          ),
        ],
      ),
    ),
  );
  Widget _field(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !_busy,
      decoration: InputDecoration(labelText: label),
      validator: (v) {
        final value = (v ?? '').trim();
        if (value.length < min || value.length > max) {
          return 'Debe tener entre $min y $max caracteres.';
        }
        if (controller == _username && value.contains(RegExp(r'\s'))) {
          return 'No puede contener espacios.';
        }
        return null;
      },
    ),
  );
}
