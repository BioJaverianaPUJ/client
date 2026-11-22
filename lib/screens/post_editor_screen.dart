import 'package:flutter/material.dart';
import '../models/community.dart';
import '../navigation/app_routes.dart';
import '../services/photo_service.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';
import '../widgets/post_card.dart' show LinkedObservation, PostPreviewCard;
import '../widgets/post_comments.dart' show MentionSuggestions;

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({super.key, this.post, this.sighting});
  final CommunityPost? post;
  final Sighting? sighting;
  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends State<PostEditorScreen> {
  late final _title = TextEditingController(text: widget.post?.title);
  late final _text = TextEditingController(text: widget.post?.text);
  late final _retained = [...?widget.post?.images];
  final List<LocalPhoto> _photos = [];
  late Sighting? _sighting = widget.sighting ?? widget.post?.sighting;
  String? _error;
  bool _busy = false, _saved = false, _unlinked = false, _preview = false;
  bool get _dirty =>
      _title.text != (widget.post?.title ?? '') ||
      _text.text != (widget.post?.text ?? '') ||
      _photos.isNotEmpty ||
      _retained.length != (widget.post?.images.length ?? 0) ||
      _sighting != (widget.sighting ?? widget.post?.sighting);
  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick(bool camera) async {
    final remaining = 10 - _photos.length - _retained.length;
    if (remaining <= 0) {
      showMessage(context, 'Ya seleccionaste diez imágenes.');
      return;
    }
    setState(() => _busy = true);
    try {
      final photos = await PhotoService().pick(
        camera: camera,
        limit: remaining,
        // Cada foto se encuadra antes de agregarla a la publicación.
        crop: PhotoCrop.post,
      );
      if (mounted) setState(() => _photos.addAll(photos));
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _associate() async {
    setState(() => _busy = true);
    try {
      final sightings = (await AppScope.read(
        context,
      ).community.sightings()).where((s) => s.canPublish).toList();
      if (!mounted) return;
      final selected = await showModalBottomSheet<Sighting>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .6,
            child: sightings.isEmpty
                ? const StatusPanel(
                    title: 'Sin observaciones disponibles',
                    message:
                        'Puedes publicar una observación después de identificarla.',
                  )
                : ListView(
                    children: [
                      for (final sighting in sightings)
                        ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox.square(
                              dimension: 48,
                              child: sighting.photo.isEmpty
                                  ? const Icon(Icons.eco_outlined)
                                  : RemotePhoto(sighting.photo, height: 48),
                            ),
                          ),
                          title: Text(sighting.species),
                          subtitle: Text(sighting.status.label),
                          onTap: () => Navigator.pop(context, sighting),
                        ),
                    ],
                  ),
          ),
        ),
      );
      if (mounted && selected != null) setState(() => _sighting = selected);
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final draft = PostDraft(
      title: _title.text.trim(),
      text: _text.text.trim(),
      photos: _photos,
      retainedImages: _retained,
      sighting: _sighting,
      observationId: _unlinked ? null : widget.post?.observationId,
    );
    final error =
        draft.validate() ??
        (draft.text.isEmpty ? 'Agrega una descripción a tu publicación.' : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppScope.read(
        context,
      ).community.savePost(draft, id: widget.post?.id);
      if (!mounted) return;
      setState(() => _saved = true);
      final isNew = widget.post == null;
      final messenger = ScaffoldMessenger.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (isNew) {
          // Lleva al inicio, que se recarga con la publicación nueva arriba.
          AppRoutes.enterApp(context);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('¡Listo! Tu publicación ya está en el inicio.'),
            ),
          );
        } else {
          Navigator.pop(context, true);
          messenger.showSnackBar(
            const SnackBar(content: Text('Cambios guardados.')),
          );
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _choosePhotoSource() async {
    final camera = await showModalBottomSheet<bool>(
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
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(sheet, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(sheet, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (camera != null && mounted) await _pick(camera);
  }

  List<Widget> _previewImages() => [
    for (final image in _retained) RemotePhoto(image, height: 340),
    for (final photo in _photos)
      Image.memory(
        photo.bytes,
        height: 340,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    // La foto de la observación vinculada también se muestra en la publicación.
    if ((_sighting?.photo ?? '').isNotEmpty &&
        !_retained.contains(_sighting!.photo))
      RemotePhoto(_sighting!.photo, height: 340),
  ];

  Widget _photoPicker() {
    final total = _photos.length + _retained.length;
    final editing = widget.post != null;
    if (total == 0 && !editing) {
      return InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: _busy ? null : _choosePhotoSource,
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: BioTheme.lime.withValues(alpha: 0.35),
              width: 1.4,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BioTheme.lime.withValues(alpha: 0.14),
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 36,
                  color: BioTheme.lime,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Agrega fotos de tu descubrimiento',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hasta 10 imágenes · Cámara o galería',
                style: TextStyle(color: BioTheme.textMuted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 18,
              color: BioTheme.lime,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Fotos',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
            Text(
              '$total/10',
              style: const TextStyle(
                fontSize: 12,
                color: BioTheme.textSecondary,
              ),
            ),
          ],
        ),
        if (editing)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Por ahora puedes editar el texto y la observación; las imágenes se conservan.',
              style: TextStyle(fontSize: 12.5, color: BioTheme.textSecondary),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final image in [..._retained])
                _Thumb(
                  cover: image == _retained.first,
                  image: RemotePhoto(image, height: 112),
                  onRemove: _busy || editing
                      ? null
                      : () => setState(() => _retained.remove(image)),
                ),
              for (final photo in [..._photos])
                _Thumb(
                  cover: _retained.isEmpty && photo == _photos.first,
                  image: Image.memory(
                    photo.bytes,
                    height: 112,
                    width: 112,
                    fit: BoxFit.cover,
                  ),
                  onRemove: _busy || editing
                      ? null
                      : () => setState(() => _photos.remove(photo)),
                ),
              if (!editing && total < 10)
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _busy ? null : _choosePhotoSource,
                  child: Container(
                    width: 112,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: BioTheme.lime.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: BioTheme.lime, size: 30),
                        SizedBox(height: 4),
                        Text(
                          'Agregar',
                          style: TextStyle(
                            color: BioTheme.lime,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _observation() => _EditorSection(
    icon: Icons.eco_outlined,
    title: 'Observación',
    trailing: _sighting == null ? 'Opcional' : null,
    children: [
      if (_sighting != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: LinkedObservation(sighting: _sighting!)),
              IconButton(
                tooltip: 'Desvincular observación',
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _sighting = null;
                        _unlinked = true;
                      }),
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
        ),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _associate,
          icon: const Icon(Icons.eco_outlined),
          label: Text(
            _sighting == null
                ? 'Asociar una observación'
                : 'Cambiar observación',
          ),
        ),
      ),
    ],
  );

  Widget _form(bool available) => ListView(
    key: const ValueKey('form'),
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
    children: [
      _photoPicker(),
      const SizedBox(height: 22),
      TextField(
        controller: _title,
        onChanged: (_) => setState(() {}),
        enabled: !_busy,
        maxLength: 200,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Título *',
          hintText: 'Ej.: Un colibrí en el jardín central',
        ),
      ),
      // Escribe @ para mencionar a alguien en el título o la descripción.
      MentionSuggestions(controller: _title),
      const SizedBox(height: 12),
      TextField(
        controller: _text,
        onChanged: (_) => setState(() {}),
        enabled: !_busy,
        maxLength: 200,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Descripción *',
          hintText:
              'Cuéntanos qué viste, dónde y cuándo. Usa @ para mencionar.',
          alignLabelWithHint: true,
        ),
      ),
      MentionSuggestions(controller: _text),
      const SizedBox(height: 16),
      _observation(),
      const SizedBox(height: 14),
      const Text(
        'Las fotos de una publicación no se usan para identificar especies.',
        style: TextStyle(color: BioTheme.textMuted, fontSize: 12.5),
      ),
      if (!available)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'La publicación de contenido aún no está disponible. Puedes preparar el contenido aquí; no se guardará al salir.',
            style: TextStyle(fontSize: 12.5, color: BioTheme.textSecondary),
          ),
        ),
    ],
  );

  Widget _previewView() {
    final user = AppScope.watch(context).user;
    final missing = _title.text.trim().isEmpty || _text.text.trim().isEmpty;
    return ListView(
      key: const ValueKey('preview'),
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
          child: Text(
            'Así verá la comunidad tu publicación',
            textAlign: TextAlign.center,
            style: TextStyle(color: BioTheme.textMuted, fontSize: 13),
          ),
        ),
        PostPreviewCard(
          authorName: user?.username ?? 'Tú',
          avatar: user?.profilePictureUrl,
          title: _title.text.trim(),
          text: _text.text.trim(),
          images: _previewImages(),
          sighting: _sighting,
        ),
        if (missing)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: TextButton.icon(
              onPressed: () => setState(() => _preview = false),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Completa el título y la descripción para publicar',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = AppScope.watch(context).community.available;
    final ready =
        !_busy &&
        available &&
        _title.text.trim().isNotEmpty &&
        _text.text.trim().isNotEmpty;
    final label = widget.post == null ? 'Publicar' : 'Guardar';
    return PopScope(
      canPop: _saved || (!_dirty && !_busy),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _busy) return;
        if (await confirmAction(
          context,
          'Descartar cambios',
          'Los cambios de esta publicación no se han guardado.',
        )) {
          if (!mounted) return;
          setState(() => _saved = true);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
        }
      },
      child: CommunityScaffold(
        title: widget.post == null ? 'Nueva publicación' : 'Editar publicación',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: ready ? _save : null,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: ready
                      ? BioTheme.lime
                      : BioTheme.lime.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: false,
                      icon: Icon(Icons.edit_outlined, size: 18),
                      label: Text('Escribir'),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: Icon(Icons.visibility_outlined, size: 18),
                      label: Text('Vista previa'),
                    ),
                  ],
                  selected: {_preview},
                  onSelectionChanged: (value) {
                    FocusScope.of(context).unfocus();
                    setState(() => _preview = value.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? BioTheme.lime
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? BioTheme.iconDark
                          : BioTheme.textSecondary,
                    ),
                    side: WidgetStatePropertyAll(
                      BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _preview ? _previewView() : _form(available),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: BioTheme.danger),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: _busy || !available ? null : _save,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_busy ? 'Espera un momento…' : label),
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

/// Bloque de vidrio con título para agrupar controles del editor y darles aire.
class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String? trailing;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => BioGlassCard(
    margin: EdgeInsets.zero,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: BioTheme.lime),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 12,
                  color: BioTheme.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, this.onRemove, this.cover = false});
  final Widget image;
  final bool cover;
  final VoidCallback? onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 112,
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (cover)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: BioTheme.lime,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Portada',
                    style: TextStyle(
                      color: BioTheme.iconDark,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (onRemove != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: BioTheme.backgroundDeep.withValues(alpha: .75),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onRemove,
                    child: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.close, size: 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
