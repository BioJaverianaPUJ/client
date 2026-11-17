import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/photo_service.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';

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
  bool _busy = false, _saved = false, _unlinked = false;
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
    final error = draft.validate();
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (mounted) setState(() => _error = messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'Comparte una historia del campus',
            style: TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las fotos de una publicación no se usan para identificar especies.',
            style: TextStyle(color: BioTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            enabled: !_busy,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Título *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _text,
            onChanged: (_) => setState(() {}),
            enabled: !_busy,
            maxLength: 200,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos más (opcional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          _EditorSection(
            icon: Icons.photo_library_outlined,
            title: 'Imágenes',
            trailing: '${_photos.length + _retained.length}/10',
            children: [
              if (widget.post != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Por ahora puedes editar el texto y la observación; las imágenes se conservan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: BioTheme.textSecondary,
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || widget.post != null
                          ? null
                          : () => _pick(true),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Cámara'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy || widget.post != null
                          ? null
                          : () => _pick(false),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galería'),
                    ),
                  ),
                ],
              ),
              if (_retained.isNotEmpty || _photos.isNotEmpty) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 112,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final image in [..._retained])
                        _Thumb(
                          image: RemotePhoto(image, height: 112),
                          onRemove: _busy || widget.post != null
                              ? null
                              : () => setState(() => _retained.remove(image)),
                        ),
                      for (final photo in [..._photos])
                        _Thumb(
                          image: Image.memory(
                            photo.bytes,
                            height: 112,
                            width: 112,
                            fit: BoxFit.cover,
                          ),
                          onRemove: _busy || widget.post != null
                              ? null
                              : () => setState(() => _photos.remove(photo)),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _EditorSection(
            icon: Icons.eco_outlined,
            title: 'Observación',
            trailing: _sighting == null ? 'Opcional' : null,
            children: [
              if (_sighting != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                  decoration: BoxDecoration(
                    color: BioTheme.backgroundDeep.withValues(alpha: .4),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sighting!.species,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _sighting!.status.label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: BioTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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
          ),
          if (!AppScope.watch(context).community.available)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'La publicación de contenido aún no está disponible. Puedes preparar el contenido aquí; no se guardará al salir.',
                style: TextStyle(fontSize: 12.5, color: BioTheme.textSecondary),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                _error!,
                style: const TextStyle(color: BioTheme.danger),
              ),
            ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _busy || !AppScope.watch(context).community.available
                ? null
                : _save,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(
              _busy
                  ? 'Espera un momento…'
                  : widget.post == null
                  ? 'Publicar'
                  : 'Guardar cambios',
            ),
          ),
        ],
      ),
    ),
  );
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
  const _Thumb({required this.image, this.onRemove});
  final Widget image;
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
