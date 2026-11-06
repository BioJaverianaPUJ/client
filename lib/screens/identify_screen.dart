import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/community.dart';
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
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Cámara',
    tab: BioTab.identify,
    body: ListView(
      padding: const EdgeInsets.all(20),
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
            borderRadius: BorderRadius.circular(24),
            child: Image.memory(_photo!.bytes, height: 300, fit: BoxFit.cover),
          )
        else
          BioGlassCard(
            frosted: true,
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'IDENTIFICACIÓN',
                    style: TextStyle(letterSpacing: 2, color: BioTheme.lime),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minHeight: 270),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: BioTheme.backgroundDeep.withValues(alpha: .48),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: BioTheme.lime.withValues(alpha: .4),
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassIcon(
                        icon: Icons.camera_alt_outlined,
                        size: 68,
                        iconSize: 34,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Encuadra una especie',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Animales, plantas y árboles',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BioTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 6),
                  child: Text('Una foto, un descubrimiento'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        if (_location != null)
          Text(
            'Ubicación: ${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)} · precisión ${_location!.accuracy.toStringAsFixed(1)} m',
          ),
        FilledButton.icon(
          onPressed: _busy ? null : _capture,
          icon: const Icon(Icons.camera_alt),
          label: Text(_photo == null ? 'Tomar fotografía' : 'Volver a tomar'),
        ),
        const SizedBox(height: 8),
        const Text(
          'Solo se admite una fotografía tomada con la cámara. Las imágenes de galería se reservan para publicaciones.',
        ),
        const SizedBox(height: 16),
        if (!AppScope.watch(context).community.observationsAvailable)
          const BioGlassCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'La identificación de especies aún no está disponible. Puedes comprobar la cámara y la ubicación, pero la captura no se enviará ni se guardará como observación.',
              ),
            ),
          ),
        if (_busy) ...[
          const LinearProgressIndicator(),
          Padding(padding: const EdgeInsets.all(12), child: Text(_stage)),
        ],
        if (_error != null)
          StatusPanel(
            title: 'No pudimos completar la captura',
            message: messageFor(_error!),
            icon: Icons.info_outline,
          ),
        if (_photo != null)
          FilledButton(
            onPressed:
                _busy ||
                    !AppScope.watch(context).community.observationsAvailable
                ? null
                : _send,
            child: const Text('Identificar y guardar observación'),
          ),
        TextButton(
          onPressed: () => Geolocator.openAppSettings(),
          child: const Text('Revisar permisos del dispositivo'),
        ),
      ],
    ),
  );
}
