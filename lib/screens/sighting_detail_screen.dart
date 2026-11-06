import 'dart:async';
import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';
import 'post_editor_screen.dart';

class SightingDetailScreen extends StatefulWidget {
  const SightingDetailScreen({super.key, required this.sighting});
  final Sighting sighting;
  @override
  State<SightingDetailScreen> createState() => _SightingDetailScreenState();
}

class _SightingDetailScreenState extends State<SightingDetailScreen> {
  late Sighting _item = widget.sighting;
  bool _busy = false, _requested = false;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _item.retryAt != null) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _action(String action) async {
    final repo = AppScope.read(context).community;
    if (action == 'delete' &&
        !await confirmAction(
          context,
          'Eliminar observación',
          'Se eliminará también su fotografía y dejará de mostrarse en la publicación asociada. Tu experiencia y logros se conservan.',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      if (action == 'delete') {
        await repo.deleteSighting(_item.id);
        if (mounted) Navigator.pop(context);
      }
      if (action == 'review') {
        await repo.requestReview(_item.id);
        if (mounted) setState(() => _requested = true);
      }
      if (action == 'refresh') {
        final updated = await repo.refreshSighting(_item.id);
        if (mounted) setState(() => _item = updated);
      }
      if (action == 'retry') {
        final updated = await repo.retry(_item.id);
        if (mounted) setState(() => _item = updated);
      }
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _item.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    return CommunityScaffold(
      title: 'Observación',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          RemotePhoto(_item.photo),
          const SizedBox(height: 16),
          Text(_item.species, style: Theme.of(context).textTheme.headlineSmall),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(switch (_item.status) {
                Verification.verified => Icons.verified_outlined,
                Verification.unverified => Icons.help_outline,
                Verification.failed => Icons.error_outline,
                Verification.processing => Icons.hourglass_top,
              }),
              label: Text(_item.status.label),
            ),
          ),
          Text(
            'Confianza: ${_item.confidence == null ? 'No disponible' : '${(_item.confidence! * 100).toStringAsFixed(1)} %'}',
          ),
          Text('Ubicación: ${_item.point.latitude}, ${_item.point.longitude}'),
          Text('Fecha: ${dateLabel(_item.date.toLocal())}'),
          Text(
            _item.published
                ? 'Publicada en la comunidad'
                : 'Guardada en tu lista personal',
          ),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          if (_item.canPublish && AppScope.read(context).community.available)
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostEditorScreen(sighting: _item),
                      ),
                    ),
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Crear publicación'),
            ),
          if (_item.canRequestReview && !_requested)
            OutlinedButton(
              onPressed: _busy ? null : () => _action('review'),
              child: const Text('Solicitar revisión'),
            ),
          if (_requested || _item.reviewRequested)
            const Text(
              'Revisión solicitada. La observación conserva su estado de verificación.',
            ),
          if (_item.status == Verification.processing)
            OutlinedButton(
              onPressed: _busy ? null : () => _action('refresh'),
              child: const Text('Consultar resultado'),
            ),
          if (_item.status == Verification.unverified)
            const Text(
              'El reconocimiento terminó. El servidor aún no informa una verificación oficial por confianza y proximidad.',
            ),
          if (_item.status == Verification.failed &&
              AppScope.read(context).community.observationRetryAvailable) ...[
            const Text(
              'La identificación falló por un problema técnico. Puedes reenviarla cuando termine el tiempo de espera.',
            ),
            FilledButton(
              onPressed: _busy || seconds > 0 ? null : () => _action('retry'),
              child: Text(
                seconds > 0
                    ? 'Reintentar en ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
                    : 'Reenviar observación',
              ),
            ),
          ],
          if (AppScope.read(context).community.observationDeletionAvailable)
            TextButton.icon(
              onPressed: _busy ? null : () => _action('delete'),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar observación'),
            ),
        ],
      ),
    );
  }
}
