import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/community.dart';
import '../widgets/photo_capture_guide.dart';
import '../theme/bio_theme.dart';
import '../widgets/glass/glass_icon.dart';
import '../services/photo_service.dart';
import '../services/location_service.dart';
import '../services/community_repository.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'sighting_detail_screen.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});
  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  LocalPhoto? _photo;
  Position? _location;
  DateTime? _capturedAt;
  Object? _error;
  bool _busy = false;
  String _stage = '';
  Future<void> _capture() async {
    setState(() {
      _busy = true;
      _error = null;
      _photo = null;
      _location = null;
      _stage = 'Comprobando ubicación…';
    });
    try {
      await LocationService.current();
      if (!mounted) return;
      setState(() => _stage = 'Abriendo cámara…');
      final photos = await PhotoService().pick(camera: true);
      if (photos.isEmpty || !mounted) return;
      final capturedAt = DateTime.now().toUtc();
      setState(() => _stage = 'Obteniendo la ubicación de la captura…');
      final position = await LocationService.current();
      if (position.accuracy > 5) {
        throw const FeatureUnavailable(
          'La ubicación todavía no tiene suficiente precisión. Busca un lugar abierto y vuelve a tomar la fotografía.',
        );
      }
      if (mounted) {
        setState(() {
          _photo = photos.single;
          _location = position;
          _capturedAt = capturedAt;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    if (_photo == null || _location == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _stage = 'Validando ubicación y enviando…';
    });
    try {
      final repo = AppScope.read(context).community;
      final boundary = await repo.campusBoundary();
      final point = LatLng(_location!.latitude, _location!.longitude);
      if (boundary.length < 3) {
        throw const FeatureUnavailable(
          'El límite oficial del campus aún no está disponible. La observación no se ha enviado.',
        );
      }
      if (!LocationService.inside(point, boundary)) {
        throw const FeatureUnavailable(
          'La fotografía fue tomada fuera del límite del campus. No se ha enviado.',
        );
      }
      if (mounted) {
        setState(
          () => _stage =
              'Identificando la especie. Puedes seguir usando la aplicación.',
        );
      }
      final sighting = await repo.submit(
        _photo!,
        point,
        _location!.accuracy,
        _capturedAt!,
      );
      if (!mounted) return;
      setState(() {
        _photo = null;
        _location = null;
      });
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SightingDetailScreen(sighting: sighting),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = AppScope.watch(context).community.observationsAvailable;
    return CommunityScaffold(
      title: 'Cámara',
      tab: BioTab.identify,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          const BioPageHeading(
            eyebrow: 'Identifica una especie',
            title: 'Descubre qué',
            accent: 'estás viendo.',
            description:
                'Toma una fotografía de una planta o un animal dentro del campus. Necesitamos cámara y ubicación para registrar la observación.',
          ),
          if (_photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  Image.memory(
                    _photo!.bytes,
                    height: 320,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BioTheme.backgroundDeep.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Foto lista para identificar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BioTheme.lime,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            BioGlassCard(
              frosted: true,
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(14),
              child: SizedBox(
                height: 250,
                child: CustomPaint(
                  painter: _ViewfinderPainter(),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GlassIcon(
                          icon: Icons.camera_alt_outlined,
                          size: 64,
                          iconSize: 32,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Encuadra una especie',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Plantas, árboles y animales',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: BioTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const PhotoCaptureGuide(),
          const SizedBox(height: 18),
          if (_location != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: BioTheme.lime,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)} · precisión ${_location!.accuracy.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 12,
                        color: BioTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_photo != null) ...[
            FilledButton.icon(
              onPressed: _busy || !available ? null : _send,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Identificar y guardar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _capture,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a tomar'),
            ),
          ] else
            FilledButton.icon(
              onPressed: _busy ? null : _capture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar fotografía'),
            ),
          if (_busy) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 4),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                _stage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: BioTheme.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Solo se admite una fotografía tomada con la cámara. Las imágenes de galería se reservan para publicaciones.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: BioTheme.textMuted),
          ),
          if (!available)
            const BioGlassCard(
              margin: EdgeInsets.only(top: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'La identificación de especies aún no está disponible. Puedes comprobar la cámara y la ubicación, pero la captura no se enviará ni se guardará como observación.',
                ),
              ),
            ),
          if (_error != null)
            StatusPanel(
              title: 'No pudimos completar la captura',
              message: messageFor(_error!),
              icon: Icons.info_outline,
            ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: () => Geolocator.openAppSettings(),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Revisar permisos del dispositivo'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Esquinas tipo visor de cámara para el área de captura.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BioTheme.lime.withValues(alpha: .7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 14.0;
    const arm = 30.0;
    const l = inset, t = inset;
    final r = size.width - inset, b = size.height - inset;
    for (final (x, y, dx, dy) in [
      (l, t, 1.0, 1.0),
      (r, t, -1.0, 1.0),
      (l, b, 1.0, -1.0),
      (r, b, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(Offset(x, y), Offset(x + arm * dx, y), paint)
        ..drawLine(Offset(x, y), Offset(x, y + arm * dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
