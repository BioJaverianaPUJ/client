import 'package:flutter/material.dart';
import '../models/community.dart';
import '../services/photo_service.dart';
import '../state/app_scope.dart';
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
  bool _busy = false, _saved = false;
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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Comparte una historia del campus',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Las fotos de una publicación no se usan para identificar especies.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            onChanged: (_) => setState(() {}),
            enabled: !_busy,
            decoration: const InputDecoration(labelText: 'Título *'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            onChanged: (_) => setState(() {}),
            enabled: !_busy,
            minLines: 3,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Cuéntanos más (opcional)',
            ),
          ),
          const SizedBox(height: 16),
          Text('Imágenes: ${_photos.length + _retained.length}/10'),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(true),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Cámara'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(false),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Galería'),
              ),
            ],
          ),
          for (final image in [..._retained])
            Column(
              children: [
                RemotePhoto(image, height: 160),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _retained.remove(image)),
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar imagen'),
                ),
              ],
            ),
          for (final photo in [..._photos])
            Column(
              children: [
                Image.memory(photo.bytes, height: 160, fit: BoxFit.cover),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _photos.remove(photo)),
                  icon: const Icon(Icons.close),
                  label: const Text('Quitar imagen'),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (_sighting != null)
            ListTile(
              title: Text(_sighting!.species),
              subtitle: Text(_sighting!.status.label),
              trailing: IconButton(
                tooltip: 'Desvincular observación',
                onPressed: _busy
                    ? null
                    : () => setState(() => _sighting = null),
                icon: const Icon(Icons.link_off),
              ),
            ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _associate,
            icon: const Icon(Icons.eco_outlined),
            label: const Text('Asociar una observación'),
          ),
          if (!AppScope.watch(context).community.available)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'La publicación de contenido aún no está disponible. Puedes preparar el contenido aquí; no se guardará al salir.',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
          FilledButton(
            onPressed: _busy || !AppScope.watch(context).community.available
                ? null
                : _save,
            child: Text(
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
