import 'account_screen.dart';
import '../widgets/profile_experience.dart';
import 'package:flutter/material.dart';
import '../widgets/glass/glass_icon.dart';
import '../models/user_profile.dart';
import '../models/community.dart';
import '../models/gender.dart';
import '../navigation/app_routes.dart';
import '../services/photo_service.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'home_screen.dart';

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
  bool get _own =>
      widget.userId == null || widget.userId == AppScope.read(context).user?.id;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  @override
  Widget build(BuildContext context) {
    final user = _user ?? (_own ? AppScope.watch(context).user : null);
    return CommunityScaffold(
      title: _own ? 'Mi perfil' : 'Perfil',
      tab: widget.userId == null ? BioTab.profile : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BioPageHeading(
              eyebrow: 'Tu perfil',
              title: 'Tu huella en',
              accent: 'el campus.',
              description:
                  'Tus descubrimientos, tu comunidad y una nueva forma de explorar.',
            ),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              StatusPanel(
                title: 'No pudimos cargar el perfil',
                message: messageFor(_error!),
                action: _load,
              ),
            if (user == null && _own)
              OutlinedButton.icon(
                onPressed: () => AppRoutes.logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            if (user != null) ...[
              if (user.bannerUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: RemotePhoto(user.bannerUrl!, height: 160),
                )
              else
                const BioGlassCard(
                  frosted: true,
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GlassIcon(
                        icon: Icons.eco_outlined,
                        size: 52,
                        iconSize: 27,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'EXPLORADOR JAVERIANO',
                        textAlign: TextAlign.center,
                        style: TextStyle(letterSpacing: 2, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              BioGlassCard(
                frosted: true,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user.profilePictureUrl != null)
                      Center(
                        child: ClipOval(
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: RemotePhoto(
                              user.profilePictureUrl!,
                              height: 96,
                            ),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: GlassIcon(
                          icon: Icons.person_outline,
                          size: 76,
                          iconSize: 40,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text('@${user.username}', textAlign: TextAlign.center),
                    if (_own) ...[
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(user.email, textAlign: TextAlign.center),
                      ),
                      FilledButton.icon(
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
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar perfil'),
                      ),
                    ],
                  ],
                ),
              ),
              if (_own) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: _busy ? null : () => _media('profile-picture'),
                      child: const Text('Cambiar foto'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => _media('banner'),
                      child: const Text('Cambiar banner'),
                    ),
                    if (user.profilePictureUrl != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _media('profile-picture', remove: true),
                        child: const Text('Eliminar foto'),
                      ),
                    if (user.bannerUrl != null)
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => _media('banner', remove: true),
                        child: const Text('Eliminar banner'),
                      ),
                  ],
                ),
                BioGlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.eco_outlined),
                    title: const Text('Mis observaciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.records),
                  ),
                ),
                BioGlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: const Text('Misiones y logros'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        AppRoutes.goTo(context, AppRoutes.gamification),
                  ),
                ),
                BioGlassCard(
                  child: ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('Catálogo de especies'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.explore),
                  ),
                ),
              ],
              ProfileExperience(key: ValueKey(user), userId: user.id),
              _ProfileActivity(userId: user.id),
              if (_own) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Cambiar contraseña'),
                  subtitle: const Text('Aún no disponible'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.person_remove_outlined),
                  title: const Text('Eliminar mi cuenta'),
                  subtitle: const Text('Aún no disponible'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountScreen(delete: true),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => AppRoutes.logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileActivity extends StatefulWidget {
  const _ProfileActivity({required this.userId});
  final String userId;
  @override
  State<_ProfileActivity> createState() => _ProfileActivityState();
}

class _ProfileActivityState extends State<_ProfileActivity> {
  List<CommunityPost> _posts = [];
  String? _cursor;
  Object? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final repo = AppScope.read(context).community;
    try {
      final page = await repo.feed(
        authorId: widget.userId,
        cursor: reset ? null : _cursor,
      );
      if (mounted) {
        setState(() {
          _posts = reset ? page.items : [..._posts, ...page.items];
          _cursor = page.nextCursor;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Publicaciones',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      for (final post in _posts)
        PostCard(post: post, onChanged: () => _load(reset: true)),
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_error != null)
        StatusPanel(
          title: 'Actividad no disponible',
          message:
              'Las publicaciones se mostrarán cuando este servicio esté disponible.',
          action: () => _load(reset: true),
        ),
      if (!_busy && _error == null && _posts.isEmpty)
        const Text('Sin publicaciones todavía.'),
      if (_cursor != null)
        TextButton(
          onPressed: _busy ? null : _load,
          child: const Text('Ver más publicaciones'),
        ),
    ],
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
