import '../theme/bio_theme.dart';
import 'campus_3d_screen.dart';
import 'dart:async';
import '../config/campus_reference.dart';
import '../config/map_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/community.dart';
import '../models/map_cluster.dart';
import '../services/location_service.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'explore_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusZone});
  final CampusZone? focusZone;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final _map = MapController();
  final List<Map<String, dynamic>> _specimens = [];
  List<LatLng> _boundary = [];
  List<CampusZone> _zones = [];
  List<Sighting> _animals = [];
  Set<String> _verifiedSpecimens = {};
  LatLng? _position;
  bool _plants = true, _showAnimals = true, _green = true, _interest = true;
  bool _loading = true, _locating = false, _more = false, _onlineLayers = false;
  int _page = 0;
  double _zoom = 16;
  bool _tileFailed = false;
  Object? _error;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _map.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed && _position != null) {
      _scheduleLocation();
    }
  }

  void _scheduleLocation() {
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _locate(center: false),
    );
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _tileFailed = false;
    });
    final session = AppScope.read(context);
    try {
      final page = await session.catalog.page('specimens', more ? _page : 0);
      if (!mounted) return;
      setState(() {
        if (!more) {
          _specimens.clear();
          _page = 0;
        }
        _specimens.addAll(page.items);
        _page++;
        _more = page.hasNext;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
    if (!more && session.community.observationsAvailable) {
      try {
        final animals = await session.community.sightings();
        if (mounted) {
          setState(() {
            _verifiedSpecimens = animals
                .where(
                  (s) =>
                      s.status == Verification.verified && s.specimen != null,
                )
                .map((s) => s.specimen!['id'] as String)
                .toSet();
            _animals = animals
                .where(
                  (s) =>
                      s.animal &&
                      s.status != Verification.failed &&
                      s.status != Verification.processing,
                )
                .toList();
          });
        }
      } catch (e) {
        if (mounted) setState(() => _error = e);
      }
    }
    if (!more && session.community.available) {
      try {
        final boundary = await session.community.campusBoundary();
        final zones = await session.community.zones();
        if (mounted) {
          setState(() {
            _boundary = boundary;
            _zones = zones;
            _onlineLayers = true;
          });
        }
      } catch (e) {
        if (mounted) showMessage(context, messageFor(e));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _locate({bool center = true}) async {
    if (_locating ||
        !mounted ||
        (WidgetsBinding.instance.lifecycleState != null &&
            WidgetsBinding.instance.lifecycleState !=
                AppLifecycleState.resumed)) {
      return;
    }
    setState(() => _locating = true);
    try {
      final location = await LocationService.current();
      if (!mounted ||
          (WidgetsBinding.instance.lifecycleState != null &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed)) {
        return;
      }
      final point = LatLng(location.latitude, location.longitude);
      setState(() => _position = point);
      if (center) _map.move(point, 17);
      _scheduleLocation();
    } catch (e) {
      if (mounted && center) showMessage(context, messageFor(e));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _detail(Map<String, dynamic> specimen) async {
    try {
      final species = await AppScope.read(
        context,
      ).catalog.species(specimen['speciesId'] as String);
      if (mounted) {
        showSpecies(
          context,
          species,
          specimen: _verifiedSpecimens.contains(specimen['id'])
              ? specimen
              : null,
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, messageFor(e));
    }
  }

  Future<void> _openCluster(SpecimenCluster cluster) async {
    if (_map.camera.zoom < 18) {
      _map.move(cluster.center, _map.camera.zoom + 1);
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '${cluster.items.length} especímenes en esta ubicación',
              ),
            ),
            for (var i = 0; i < cluster.items.length; i++)
              ListTile(
                leading: const Icon(Icons.park_outlined),
                title: Text('Espécimen ${i + 1}'),
                subtitle: Text('Consultar especie y detalles'),
                onTap: () => Navigator.pop(context, cluster.items[i]),
              ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) await _detail(selected);
  }

  @override
  Widget build(BuildContext context) {
    final zones = [..._zones];
    if (widget.focusZone != null &&
        !zones.any((z) => z.id == widget.focusZone!.id)) {
      zones.add(widget.focusZone!);
    }
    return CommunityScaffold(
      title: 'Mapa del campus',
      tab: widget.focusZone == null ? BioTab.map : null,
      actions: [
        IconButton(
          tooltip: 'Actualizar mapa',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const BioPageHeading(
            eyebrow: 'Mapa del campus',
            title: 'Explora el',
            accent: 'campus.',
            description:
                'Descubre dónde habitan las especies y encuentra tu próximo recorrido.',
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_tileFailed)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'No pudimos cargar las imágenes del mapa. Revisa tu conexión y pulsa actualizar.',
              ),
            ),
          BioGlassCard(
            frosted: true,
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 440,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: FlutterMap(
                  mapController: _map,
                  options: MapOptions(
                    initialCenter:
                        widget.focusZone?.points.firstOrNull ??
                        const LatLng(4.6282, -74.0644),
                    initialZoom: 17,
                    initialCameraFit: widget.focusZone == null
                        ? CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(campusReference),
                            padding: const EdgeInsets.all(24),
                          )
                        : null,
                    onPositionChanged: (camera, _) {
                      if (_zoom.floor() != camera.zoom.floor()) {
                        setState(() => _zoom = camera.zoom);
                      }
                    },
                    minZoom: 14,
                    maxZoom: 19,
                  ),
                  children: [
                    ColorFiltered(
                      colorFilter: MapConfig.usesCarto
                          ? const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.srcOver,
                            )
                          : const ColorFilter.matrix([
                              .50,
                              .40,
                              .10,
                              0,
                              12,
                              .20,
                              .70,
                              .10,
                              0,
                              12,
                              .20,
                              .40,
                              .40,
                              0,
                              12,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ]),
                      child: TileLayer(
                        urlTemplate: MapConfig.tileUrl,
                        userAgentPackageName: 'co.edu.javeriana.biojaveriana',
                        errorTileCallback: (_, _, _) {
                          if (mounted && !_tileFailed) {
                            setState(() => _tileFailed = true);
                          }
                        },
                      ),
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: const [
                            LatLng(5, -75),
                            LatLng(5, -73),
                            LatLng(4, -73),
                            LatLng(4, -75),
                          ],
                          holePointsList: [
                            _boundary.length >= 3 ? _boundary : campusReference,
                          ],
                          color: const Color(0x77002E28),
                          borderStrokeWidth: 0,
                        ),
                        if (_boundary.length < 3)
                          Polygon(
                            points: campusReference,
                            color: const Color(0x11284D37),
                            borderColor: const Color(0xFF285D46),
                            borderStrokeWidth: 3,
                          ),
                        if (_boundary.length >= 3)
                          Polygon(
                            points: _boundary,
                            color: Colors.transparent,
                            borderColor: Colors.amber,
                            borderStrokeWidth: 3,
                          ),
                        for (final zone in zones.where(
                          (z) => z.interest ? _interest : _green,
                        ))
                          Polygon(
                            points: zone.points,
                            color:
                                (zone.interest ? Colors.purple : Colors.green)
                                    .withValues(alpha: .22),
                            borderColor: zone.interest
                                ? Colors.purple
                                : Colors.green,
                            borderStrokeWidth: 2,
                            label: zone.name,
                          ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        if (_plants)
                          for (final cluster in clusterSpecimens(
                            _specimens,
                            _zoom,
                          ))
                            Marker(
                              point: cluster.center,
                              width: 48,
                              height: 48,
                              child: cluster.items.length == 1
                                  ? IconButton(
                                      tooltip: 'Ver espécimen oficial',
                                      onPressed: () =>
                                          _detail(cluster.items.single),
                                      icon: const Icon(
                                        Icons.park,
                                        color: Color(0xFF164E23),
                                        size: 28,
                                      ),
                                    )
                                  : Semantics(
                                      label:
                                          '${cluster.items.length} especímenes cercanos',
                                      button: true,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: const Color(
                                            0xFF164E23,
                                          ),
                                          foregroundColor: Colors.white,
                                          shape: const CircleBorder(),
                                        ),
                                        onPressed: () => _openCluster(cluster),
                                        child: Text('${cluster.items.length}'),
                                      ),
                                    ),
                            ),
                        if (_showAnimals)
                          for (final animal in _animals)
                            Marker(
                              point: animal.point,
                              width: 48,
                              height: 48,
                              child: IconButton(
                                tooltip: animal.species,
                                onPressed: () => showMessage(
                                  context,
                                  '${animal.species} · ${animal.status.label} · ${dateLabel(animal.date)}',
                                ),
                                icon: const Icon(
                                  Icons.pets,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                        if (_position != null)
                          Marker(
                            point: _position!,
                            width: 32,
                            height: 32,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              semanticLabel: 'Tu ubicación',
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        if (MapConfig.usesCarto)
                          TextSourceAttribution(
                            'CARTO',
                            onTap: () => launchUrl(
                              Uri.parse('https://carto.com/attributions'),
                            ),
                          ),
                        TextSourceAttribution(
                          'OpenStreetMap contributors',
                          onTap: () => launchUrl(
                            Uri.parse(
                              'https://www.openstreetmap.org/copyright',
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
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _locating ? null : () => _locate(),
                  icon: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(_locating ? 'Buscando…' : 'Mi ubicación'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.school_outlined),
                  label: const Text('Ver campus'),
                  onPressed: () => _map.fitCamera(
                    CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints(
                        _boundary.length >= 3 ? _boundary : campusReference,
                      ),
                      padding: const EdgeInsets.all(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BioGlassAction(
            title: 'Explorar campus en 3D',
            subtitle: 'Recorre los edificios en volumen, gira e inclina la vista.',
            icon: Icons.view_in_ar_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Campus3DScreen()),
            ),
          ),
          const SizedBox(height: 20),
          BioGlassCard(
            margin: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.fromLTRB(20, 6, 16, 6),
                childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                leading: const Icon(
                  Icons.layers_outlined,
                  color: BioTheme.lime,
                ),
                title: const Text(
                  'Capas del mapa',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Elige qué quieres explorar',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: BioTheme.textSecondary,
                  ),
                ),
                children: [
                  _LayerTile(
                    icon: Icons.park_outlined,
                    color: const Color(0xFF9CCB72),
                    title: 'Especímenes oficiales de plantas',
                    value: _plants,
                    onChanged: (v) => setState(() => _plants = v),
                  ),
                  _LayerTile(
                    icon: Icons.pets_outlined,
                    color: Colors.orange,
                    title: 'Mis observaciones de animales',
                    value: _showAnimals,
                    onChanged:
                        AppScope.read(context).community.observationsAvailable
                        ? (v) => setState(() => _showAnimals = v)
                        : null,
                  ),
                  _LayerTile(
                    icon: Icons.grass_outlined,
                    color: Colors.green,
                    title: 'Zonas verdes',
                    value: _green,
                    onChanged: _onlineLayers
                        ? (v) => setState(() => _green = v)
                        : null,
                  ),
                  _LayerTile(
                    icon: Icons.place_outlined,
                    color: Colors.purpleAccent,
                    title: 'Zonas de interés',
                    value: _interest,
                    onChanged: _onlineLayers
                        ? (v) => setState(() => _interest = v)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Geolocator.openAppSettings(),
                        icon: const Icon(Icons.settings_outlined, size: 18),
                        label: const Text('Permisos de ubicación'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!_onlineLayers)
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                'Perímetro de referencia de OpenStreetMap. El límite oficial y las zonas están pendientes de publicación.',
                style: TextStyle(fontSize: 12, color: BioTheme.textSecondary),
              ),
            ),
          if (_error != null)
            StatusPanel(
              title: 'No pudimos cargar una capa del mapa',
              message: messageFor(_error!),
              action: _load,
            ),
          if (_more)
            OutlinedButton(
              onPressed: _loading ? null : () => _load(more: true),
              child: const Text('Cargar más especímenes'),
            ),
          if (!_loading && _error == null && _specimens.isEmpty)
            const Text('No hay especímenes oficiales registrados.'),
        ],
      ),
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: value,
    onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    visualDensity: VisualDensity.compact,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    secondary: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: color),
    ),
    title: Text(title, style: const TextStyle(fontSize: 14)),
  );
}
