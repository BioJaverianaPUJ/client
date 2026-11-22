import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config/map_config.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';
import 'post_editor_screen.dart';

class SightingDetailScreen extends StatefulWidget {
  const SightingDetailScreen({super.key, required this.sighting});
  final Sighting sighting;
  @override
  State<SightingDetailScreen> createState() => _SightingDetailScreenState();
}

/// Color e ícono de cada estado de verificación.
(Color, IconData, String) _statusStyle(Verification status) => switch (status) {
  Verification.verified => (
    BioTheme.lime,
    Icons.verified_rounded,
    'Coincide con un espécimen registrado del campus.',
  ),
  Verification.unverified => (
    const Color(0xFFF2C46B),
    Icons.help_outline_rounded,
    'La identificación no alcanzó los criterios de similitud o no se asoció con un espécimen registrado. Puedes pedir que un administrador la revise.',
  ),
  Verification.failed => (
    BioTheme.danger,
    Icons.error_outline_rounded,
    'La identificación falló por un problema técnico.',
  ),
  Verification.processing => (
    const Color(0xFF8CC8E8),
    Icons.hourglass_top_rounded,
    'Estamos identificando la especie. Puedes seguir usando la aplicación.',
  ),
};

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

  Widget _hero() {
    final (color, icon, _) = _statusStyle(_item.status);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _item.photo.isEmpty
                ? const ColoredBox(
                    color: Color(0x22D4E27E),
                    child: Icon(Icons.eco_outlined, size: 64),
                  )
                : RemotePhoto(_item.photo, height: 300),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xCC002E29)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      _item.status.label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item.animal ? 'FAUNA' : 'FLORA',
                    style: const TextStyle(
                      color: BioTheme.lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _item.species,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, double? value, String hint) {
    final percent = value == null ? null : (value * 100).clamp(0, 100);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: BioTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              percent == null
                  ? '—'
                  : '${percent.toStringAsFixed(percent < 10 ? 1 : 0)} %',
              style: const TextStyle(
                color: BioTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent == null ? 0 : percent / 100,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                color: BioTheme.lime,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: const TextStyle(color: BioTheme.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard() {
    final (color, icon, text) = _statusStyle(_item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(height: 1.4, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: BioTheme.lime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: BioTheme.lime),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: BioTheme.textMuted, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: BioTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _miniMap() {
    final known = _item.point.latitude != 0 || _item.point.longitude != 0;
    if (!known) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 160,
          child: IgnorePointer(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _item.point,
                initialZoom: 17.5,
              ),
              children: [
                TileLayer(
                  urlTemplate: MapConfig.tileUrl,
                  userAgentPackageName: 'co.edu.javeriana.biojaveriana',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _item.point,
                      width: 34,
                      height: 34,
                      child: Container(
                        decoration: BoxDecoration(
                          color: BioTheme.lime,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                        child: Icon(
                          _item.animal ? Icons.pets_rounded : Icons.eco_rounded,
                          size: 16,
                          color: BioTheme.iconDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _item.retryAt?.difference(DateTime.now()).inSeconds ?? 0;
    final community = AppScope.read(context).community;
    final specimen = _item.specimen;
    return CommunityScaffold(
      title: 'Observación',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _hero(),
          const SizedBox(height: 16),
          _statusCard(),
          const SizedBox(height: 14),
          Row(
            children: [
              _metric(
                'Similitud',
                _item.similarity,
                'Mínimo 25 % para verificar',
              ),
              const SizedBox(width: 12),
              _metric('Confianza', _item.confidence, 'Certeza del modelo'),
            ],
          ),
          if (_item.status == Verification.verified && specimen != null) ...[
            const SizedBox(height: 14),
            BioGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Espécimen oficial asociado',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    _info(
                      Icons.height_rounded,
                      'Altura',
                      '${specimen['height'] ?? 'No disponible'} m',
                    ),
                    _info(
                      Icons.circle_outlined,
                      'Circunferencia',
                      '${specimen['circumference'] ?? 'No disponible'} cm',
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          BioGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _info(
                    Icons.calendar_today_rounded,
                    'Fecha',
                    dateLabel(_item.date.toLocal()),
                  ),
                  _info(
                    Icons.place_outlined,
                    'Ubicación',
                    '${_item.point.latitude.toStringAsFixed(5)}, ${_item.point.longitude.toStringAsFixed(5)}',
                  ),
                  _info(
                    _item.published
                        ? Icons.public_rounded
                        : Icons.lock_outline_rounded,
                    'Visibilidad',
                    _item.published
                        ? 'Publicada en la comunidad'
                        : 'Guardada en tu lista personal',
                  ),
                  _miniMap(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          if (_item.canPublish && community.available)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
              ),
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
          if (_item.canRequestReview && !_requested) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : () => _action('review'),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Solicitar revisión'),
            ),
          ],
          if (_requested || _item.reviewRequested)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, color: BioTheme.lime, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Revisión solicitada. Un administrador revisará esta observación.',
                      style: TextStyle(color: BioTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          if (_item.status == Verification.processing) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _busy ? null : () => _action('refresh'),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Consultar resultado'),
            ),
          ],
          if (_item.status == Verification.failed &&
              community.observationRetryAvailable) ...[
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _busy || seconds > 0 ? null : () => _action('retry'),
              child: Text(
                seconds > 0
                    ? 'Reintentar en ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}'
                    : 'Reenviar observación',
              ),
            ),
          ],
          if (community.observationDeletionAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: _busy ? null : () => _action('delete'),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar observación'),
              ),
            ),
        ],
      ),
    );
  }
}
