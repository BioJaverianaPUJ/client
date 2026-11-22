import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import '../config/campus_reference.dart';
import '../config/map_config.dart';

import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../widgets/community_widgets.dart';
import '../theme/bio_theme.dart';
import '../widgets/glass/liquid_glass.dart';

/// Vista arquitectónica opcional del campus en 3D; el mapa operativo sigue
/// siendo el 2D.
class Campus3DScreen extends StatefulWidget {
  const Campus3DScreen({super.key});
  @override
  State<Campus3DScreen> createState() => _Campus3DScreenState();
}

class _Campus3DScreenState extends State<Campus3DScreen> {
  static const _center = ml.LatLng(4.6286, -74.0640);
  static const _home = ml.CameraPosition(
    target: _center,
    zoom: 16.8,
    tilt: 58,
    bearing: -18,
  );

  late final Future<String> _style = _loadStyle();
  ml.MapLibreMapController? _controller;
  bool _flat = false;
  double _bearing = _home.bearing;
  String? _name;
  String? _detail;
  bool _showMe = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  /// Muestra el punto de la persona si ya dio permiso de ubicación.
  Future<void> _checkLocation() async {
    try {
      final p = await Geolocator.checkPermission();
      if (mounted &&
          (p == LocationPermission.whileInUse ||
              p == LocationPermission.always)) {
        setState(() => _showMe = true);
      }
    } catch (_) {}
  }

  Future<void> _goToMe() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await LocationService.current();
      if (!mounted) return;
      setState(() => _showMe = true);
      final current = _controller?.cameraPosition ?? _home;
      await _controller?.animateCamera(
        ml.CameraUpdate.newCameraPosition(
          ml.CameraPosition(
            target: ml.LatLng(position.latitude, position.longitude),
            zoom: 17.6,
            tilt: current.tilt,
            bearing: current.bearing,
          ),
        ),
        duration: const Duration(milliseconds: 700),
      );
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<String> _loadStyle() async {
    final buildings = jsonDecode(
      await rootBundle.loadString('assets/campus-buildings.geojson'),
    );
    final rings = [
      for (final area in campusAreas)
        [
          [
            for (final p in area) [p.longitude, p.latitude],
            [area.first.longitude, area.first.latitude],
          ],
        ],
    ];
    final campus = {
      'type': 'Feature',
      'properties': {},
      'geometry': {'type': 'MultiPolygon', 'coordinates': rings},
    };
    return jsonEncode({
      'version': 8,
      'light': {
        'anchor': 'viewport',
        'color': '#fffbe8',
        'intensity': 0.42,
        'position': [1.3, 200, 40],
      },
      'sources': {
        'base': {
          'type': 'raster',
          'tiles': [MapConfig.tileUrl],
          'tileSize': 256,
          'attribution': '© CARTO · © OpenStreetMap contributors',
        },
        'buildings': {'type': 'geojson', 'data': buildings},
        'campus': {'type': 'geojson', 'data': campus},
      },
      'layers': [
        {
          'id': 'background',
          'type': 'background',
          'paint': {'background-color': '#0f3a33'},
        },
        {
          'id': 'base',
          'type': 'raster',
          'source': 'base',
          // Mapa base apagado y verdoso para que resalten los edificios.
          'paint': {
            'raster-saturation': -0.75,
            'raster-brightness-max': 0.78,
            'raster-brightness-min': 0.12,
            'raster-contrast': 0.05,
            'raster-hue-rotate': 20,
          },
        },
        {
          'id': 'campus-fill',
          'type': 'fill',
          'source': 'campus',
          'paint': {'fill-color': '#d4e27e', 'fill-opacity': 0.12},
        },
        {
          'id': 'campus',
          'type': 'line',
          'source': 'campus',
          'paint': {
            'line-color': '#d4e27e',
            'line-width': 3,
            'line-opacity': 0.9,
          },
        },
        {
          'id': 'buildings',
          'type': 'fill-extrusion',
          'source': 'buildings',
          'paint': {
            // Más alto = verde más profundo.
            'fill-extrusion-color': [
              'interpolate',
              ['linear'],
              ['coalesce', ['get', 'height'], 6],
              0,
              '#e4ecd8',
              12,
              '#b9cfa6',
              25,
              '#8fb08a',
              45,
              '#5f8c72',
            ],
            'fill-extrusion-height': ['coalesce', ['get', 'height'], 6],
            'fill-extrusion-base': 0,
            'fill-extrusion-opacity': 0.92,
            'fill-extrusion-vertical-gradient': true,
          },
        },
        {
          'id': 'buildings-selected',
          'type': 'fill-extrusion',
          'source': 'buildings',
          'filter': [
            '==',
            ['get', 'osmId'],
            '',
          ],
          'paint': {
            'fill-extrusion-color': '#d4e27e',
            'fill-extrusion-height': [
              '+',
              ['coalesce', ['get', 'height'], 6],
              0.4,
            ],
            'fill-extrusion-base': 0,
            'fill-extrusion-opacity': 0.95,
          },
        },
      ],
    });
  }

  Future<void> _move({double? bearing, double? tilt, double? zoom}) async {
    final c = _controller;
    if (c == null) return;
    final current = c.cameraPosition ?? _home;
    final next = ml.CameraPosition(
      target: current.target,
      zoom: zoom ?? current.zoom,
      tilt: tilt ?? current.tilt,
      bearing: bearing ?? current.bearing,
    );
    setState(() => _bearing = next.bearing);
    await c.animateCamera(
      ml.CameraUpdate.newCameraPosition(next),
      duration: const Duration(milliseconds: 650),
    );
  }

  Future<void> _reset() async {
    setState(() {
      _flat = false;
      _bearing = _home.bearing;
    });
    await _controller?.animateCamera(
      ml.CameraUpdate.newCameraPosition(_home),
      duration: const Duration(milliseconds: 800),
    );
  }

  Future<void> _select(dynamic feature) async {
    final props = feature is Map ? feature['properties'] : null;
    final id = props is Map ? '${props['osmId'] ?? ''}' : '';
    try {
      await _controller?.setLayerFilter('buildings-selected', [
        '==',
        ['get', 'osmId'],
        id,
      ]);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (props is! Map) {
        _name = null;
        _detail = null;
        return;
      }
      final name = '${props['name'] ?? ''}'.trim();
      final height = props['height'];
      _name = name.isEmpty ? 'Edificio sin nombre' : name;
      _detail = [
        if (height is num) '${height.toStringAsFixed(1)} m de altura',
        if (props['heightSource'] != null) '${props['heightSource']}',
      ].join(' · ');
    });
  }

  @override
  Widget build(BuildContext context) => BioScene(
    illustration: null,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('Campus en 3D'),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: BioTheme.lime.withValues(alpha: .25),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66001A16),
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        Positioned.fill(child: _map()),
                        Positioned(
                          right: 12,
                          top: 12,
                          child: Column(
                            children: [
                              _MapControl(
                                tooltip: 'Orientar al norte',
                                onTap: () => _move(bearing: 0),
                                child: Transform.rotate(
                                  angle: -_bearing * 3.1415926535 / 180,
                                  child: const Icon(
                                    Icons.navigation_outlined,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MapControl(
                                tooltip: 'Girar',
                                onTap: () => _move(bearing: _bearing + 45),
                                child: const Icon(
                                  Icons.rotate_right,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _MapControl(
                                tooltip: 'Acercar',
                                onTap: () => _move(
                                  zoom:
                                      (_controller?.cameraPosition?.zoom ??
                                          _home.zoom) +
                                      .7,
                                ),
                                child: const Icon(Icons.add, size: 20),
                              ),
                              const SizedBox(height: 10),
                              _MapControl(
                                tooltip: 'Alejar',
                                onTap: () => _move(
                                  zoom:
                                      (_controller?.cameraPosition?.zoom ??
                                          _home.zoom) -
                                      .7,
                                ),
                                child: const Icon(Icons.remove, size: 20),
                              ),
                              const SizedBox(height: 10),
                              _MapControl(
                                tooltip: 'Mi ubicación',
                                onTap: _goToMe,
                                child: _locating
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location_rounded,
                                        size: 20,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              BioGlassCard(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _name == null
                          ? const Row(
                              key: ValueKey('hint'),
                              children: [
                                Icon(
                                  Icons.touch_app_outlined,
                                  color: BioTheme.lime,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Toca un edificio para ver su nombre. Gira e inclina con dos dedos.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: ValueKey(_name),
                              children: [
                                const Icon(
                                  Icons.apartment_outlined,
                                  color: BioTheme.lime,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _name!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if ((_detail ?? '').isNotEmpty)
                                        Text(
                                          _detail!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: BioTheme.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Quitar selección',
                                  onPressed: () => _select(null),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              setState(() => _flat = !_flat);
                              _move(tilt: _flat ? 0 : _home.tilt);
                            },
                            icon: Icon(
                              _flat
                                  ? Icons.view_in_ar_outlined
                                  : Icons.map_outlined,
                            ),
                            label: Text(
                              _flat ? 'Ver en 3D' : 'Vista superior',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.center_focus_strong),
                            label: const Text('Centrar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Vista ilustrativa con datos de OpenStreetMap; algunas alturas son estimadas y el terreno se muestra plano.',
                      style: TextStyle(
                        fontSize: 11,
                        color: BioTheme.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _map() => FutureBuilder<String>(
    future: _style,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No pudimos cargar la vista 3D. Regresa al mapa 2D.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return ml.MapLibreMap(
        styleString: snapshot.data!,
        initialCameraPosition: _home,
        trackCameraPosition: true,
        compassEnabled: false,
        // Punto nativo de la ubicación de la persona.
        myLocationEnabled: _showMe,
        minMaxZoomPreference: const ml.MinMaxZoomPreference(14, 20),
        onMapCreated: (controller) => _controller = controller,
        onCameraIdle: () {
          final bearing = _controller?.cameraPosition?.bearing;
          if (bearing != null && mounted && bearing != _bearing) {
            setState(() => _bearing = bearing);
          }
        },
        onMapClick: (point, coordinates) async {
          try {
            final features = await _controller?.queryRenderedFeatures(
              point,
              ['buildings'],
              null,
            );
            await _select(
              features != null && features.isNotEmpty ? features.first : null,
            );
          } catch (_) {}
        },
      );
    },
  );
}

class _MapControl extends StatelessWidget {
  const _MapControl({
    required this.tooltip,
    required this.onTap,
    required this.child,
  });
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: LiquidGlass(
      borderRadius: 16,
      width: 44,
      height: 44,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: IconTheme(
            data: const IconThemeData(color: BioTheme.lime),
            child: Center(child: child),
          ),
        ),
      ),
    ),
  );
}
