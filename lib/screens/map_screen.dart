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
import '../widgets/species_symbol.dart';
import '../navigation/app_routes.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusZone});
  final CampusZone? focusZone;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final _map = MapController();
  final List<Map<String, dynamic>> _specimens = [];
  final Map<String, Map<String, dynamic>> _speciesById = {};
  String? _groupFilter;
  List<LatLng> _boundary = [];
  List<CampusZone> _zones = [];
  List<Sighting> _animals = [];
  Set<String> _verifiedSpecimens = {};
  LatLng? _position;
  bool _plants = true, _showAnimals = true, _green = true, _interest = true;
  bool _loading = true, _locating = false, _more = false, _onlineLayers = false;
  double _zoom = 16;
  bool _tileFailed = false;
  Object? _error, _animalsError;
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _autoLocate();
    });
  }

  /// Muestra el punto de la persona si ya concedió el permiso, sin pedirlo
  /// de nuevo ni mover el mapa.
  Future<void> _autoLocate() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _locate(center: false);
      }
    } catch (_) {
      // Sin servicio de ubicación el mapa funciona igual.
    }
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
      const Duration(seconds: 10),
      (_) => _locate(center: false),
    );
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _loading = true;
      _error = null;
      _animalsError = null;
      _tileFailed = false;
    });
    final session = AppScope.read(context);
    try {
      // Se cargan todos los ejemplares para que el mapa esté completo.
      final all = <Map<String, dynamic>>[];
      for (var p = 0; ; p++) {
        final page = await session.catalog.page('specimens', p);
        all.addAll(page.items);
        if (!page.hasNext || p > 200) break;
      }
      if (!mounted) return;
      setState(() {
        _specimens
          ..clear()
          ..addAll(all);
        _more = false;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
    // Especies: dan el ícono y el color de cada ejemplar (como en el catálogo).
    try {
      final species = <String, Map<String, dynamic>>{};
      for (var p = 0; ; p++) {
        final page = await session.catalog.page('species', p);
        for (final sp in page.items) {
          species['${sp['id']}'] = sp;
        }
        if (!page.hasNext || p > 50) break;
      }
      if (mounted) {
        setState(() {
          _speciesById
            ..clear()
            ..addAll(species);
        });
      }
    } catch (_) {}
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
        if (mounted) setState(() => _animalsError = e);
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
      final species = await AppScope.read(context).catalog
          .species(specimen['speciesId'] as String);
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

  SpeciesGroup _groupOf(Map<String, dynamic> specimen) {
    final species = _speciesById['${specimen['speciesId']}'];
    return species == null ? SpeciesGroups.plant : SpeciesGroups.of(species);
  }

  Color _dominantColor(List<Map<String, dynamic>> items) {
    final counts = <Color, int>{};
    for (final s in items) {
      final c = _groupOf(s).color;
      counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<Map<String, dynamic>> get _visibleSpecimens => _groupFilter == null
      ? _specimens
      : _specimens.where((s) => _groupOf(s).label == _groupFilter).toList();

  /// Grupos presentes en el mapa con su cantidad, del más al menos común.
  List<(SpeciesGroup, int)> get _groupsPresent {
    final m = <String, (SpeciesGroup, int)>{};
    for (final s in _specimens) {
      final g = _groupOf(s);
      m[g.label] = (g, (m[g.label]?.$2 ?? 0) + 1);
    }
    return m.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
  }

  void _legend() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: BioTheme.backgroundDeep,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          const Text(
            'Leyenda del mapa',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final (g, n) in _groupsPresent)
            _LegendRow(
              marker: _SpecimenPin(group: g, size: 30),
              label: g.label,
              detail: '$n ${n == 1 ? 'ejemplar' : 'ejemplares'}',
            ),
          _LegendRow(
            marker: const _ClusterPin(count: 5, color: BioTheme.lime, size: 30),
            label: 'Varios ejemplares juntos',
            detail: 'Toca para acercar',
          ),
          const _LegendRow(
            marker: _AnimalPin(size: 30),
            label: 'Tus observaciones de animales',
          ),
          _LegendRow(
            marker: Container(
              width: 26,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: .3),
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            label: 'Zona verde',
          ),
          _LegendRow(
            marker: Container(
              width: 26,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: .3),
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            label: 'Zona de interés',
          ),
          const _LegendRow(marker: _UserDot(), label: 'Tu ubicación'),
        ],
      ),
    ),
  );

  Widget _groupChips() {
    final groups = _groupsPresent;
    if (groups.length < 2) return const SizedBox.shrink();
    Widget chip(
      String label,
      int n,
      bool selected,
      VoidCallback onTap, [
      SpeciesGroup? g,
    ]) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected
            ? BioTheme.lime
            : BioTheme.backgroundDeep.withValues(alpha: .7),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? BioTheme.lime
                : Colors.white.withValues(alpha: .14),
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (g != null) ...[
                  Icon(
                    g.icon,
                    size: 16,
                    color: selected ? BioTheme.iconDark : g.color,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$label  $n',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? BioTheme.iconDark : BioTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            chip(
              'Todos',
              _specimens.length,
              _groupFilter == null,
              () => setState(() => _groupFilter = null),
            ),
            for (final (g, n) in groups)
              chip(
                g.label,
                n,
                _groupFilter == g.label,
                () => setState(
                  () => _groupFilter = _groupFilter == g.label ? null : g.label,
                ),
                g,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _mapOverlays() => [
    if (_loading)
      const Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: LinearProgressIndicator(minHeight: 3),
      ),
    Positioned(
      top: 12,
      left: 12,
      child: _MapPill(
        icon: Icons.park_rounded,
        label: _specimens.isEmpty
            ? 'Campus Javeriana'
            : '${_visibleSpecimens.length} especímenes',
      ),
    ),
    Positioned(
      top: 12,
      right: 12,
      child: Material(
        color: BioTheme.backgroundDeep.withValues(alpha: 0.88),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _legend,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(10, 7, 12, 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: BioTheme.lime,
                ),
                SizedBox(width: 6),
                Text(
                  'Leyenda',
                  style: TextStyle(
                    color: BioTheme.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    Positioned(
      right: 12,
      bottom: 34,
      child: Column(
        children: [
          _MapButton(
            tooltip: 'Ver todo el campus',
            icon: Icons.fit_screen_rounded,
            onTap: () => _map.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(
                  _boundary.length >= 3 ? _boundary : campusAllPoints,
                ),
                padding: const EdgeInsets.all(24),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _MapButton(
            tooltip: 'Mi ubicación',
            icon: Icons.my_location_rounded,
            primary: true,
            busy: _locating,
            onTap: _locating ? null : () => _locate(),
          ),
        ],
      ),
    ),
  ];

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
          if (_plants) _groupChips(),
          Container(
            height: MediaQuery.sizeOf(context).height * 0.62 < 420.0
                ? 420.0
                : MediaQuery.sizeOf(context).height * 0.62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: BioTheme.lime.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(29),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter:
                            widget.focusZone?.points.firstOrNull ??
                            const LatLng(4.6282, -74.0644),
                        initialZoom: 17,
                        initialCameraFit: widget.focusZone == null
                            ? CameraFit.bounds(
                                bounds: LatLngBounds.fromPoints(
                                  campusAllPoints,
                                ),
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
                            userAgentPackageName:
                                'co.edu.javeriana.biojaveriana',
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
                              holePointsList: _boundary.length >= 3
                                  ? [_boundary]
                                  : campusAreas,
                              color: const Color(0x77002E28),
                              borderStrokeWidth: 0,
                            ),
                            if (_boundary.length < 3)
                              for (final area in campusAreas)
                                Polygon(
                                  points: area,
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
                                    (zone.interest
                                            ? Colors.purple
                                            : Colors.green)
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
                                _visibleSpecimens,
                                _zoom,
                              ))
                                cluster.items.length == 1
                                    ? Marker(
                                        point: cluster.center,
                                        width: 44,
                                        height: 44,
                                        child: Semantics(
                                          button: true,
                                          label:
                                              'Espécimen: ${_groupOf(cluster.items.single).label}',
                                          child: GestureDetector(
                                            onTap: () =>
                                                _detail(cluster.items.single),
                                            child: Center(
                                              child: _SpecimenPin(
                                                group: _groupOf(
                                                  cluster.items.single,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Marker(
                                        point: cluster.center,
                                        width: 52,
                                        height: 52,
                                        child: Semantics(
                                          button: true,
                                          label:
                                              '${cluster.items.length} especímenes cercanos',
                                          child: GestureDetector(
                                            onTap: () => _openCluster(cluster),
                                            child: Center(
                                              child: _ClusterPin(
                                                count: cluster.items.length,
                                                color: _dominantColor(
                                                  cluster.items,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                            if (_showAnimals)
                              for (final animal in _animals)
                                Marker(
                                  point: animal.point,
                                  width: 44,
                                  height: 44,
                                  child: Semantics(
                                    button: true,
                                    label: 'Observación: ${animal.species}',
                                    child: GestureDetector(
                                      onTap: () => showMessage(
                                        context,
                                        '${animal.species} · ${animal.status.label} · ${dateLabel(animal.date)}',
                                      ),
                                      child: const Center(child: _AnimalPin()),
                                    ),
                                  ),
                                ),
                            if (_position != null)
                              Marker(
                                point: _position!,
                                width: 40,
                                height: 40,
                                child: const Center(child: _UserDot()),
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
                  ..._mapOverlays(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_tileFailed)
            const _InlineNotice(
              icon: Icons.wifi_off_rounded,
              message: 'No pudimos cargar las imágenes del mapa. Revisa tu conexión y pulsa actualizar.',
            ),
          if (_animalsError != null)
            _InlineNotice(
              icon: Icons.pets_outlined,
              message: 'No pudimos cargar tus observaciones de animales.',
              action: _load,
            ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Text(
              'MÁS PARA EXPLORAR',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 2,
                color: BioTheme.textMuted,
              ),
            ),
          ),
          BioGlassAction(
            title: 'Biodiversidad del campus',
            subtitle: 'Conoce las especies que comparten este espacio contigo.',
            icon: Icons.eco_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.explore),
          ),
          BioGlassAction(
            title: 'Explorar campus en 3D',
            subtitle:
                'Recorre los edificios en volumen, gira e inclina la vista.',
            icon: Icons.view_in_ar_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Campus3DScreen()),
            ),
          ),
          const SizedBox(height: 8),
          const SizedBox(height: 20),
          BioGlassCard(
            margin: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
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
              title: 'No pudimos cargar los especímenes',
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

class _MapPill extends StatelessWidget {
  const _MapPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
    decoration: BoxDecoration(
      color: BioTheme.backgroundDeep.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: BioTheme.lime),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: BioTheme.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.primary = false,
    this.busy = false,
  });
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool primary, busy;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: primary
          ? BioTheme.lime
          : BioTheme.backgroundDeep.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      elevation: 4,
      shadowColor: Colors.black54,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primary ? BioTheme.iconDark : BioTheme.lime,
                    ),
                  )
                : Icon(
                    icon,
                    color: primary ? BioTheme.iconDark : BioTheme.textPrimary,
                  ),
          ),
        ),
      ),
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
    decoration: BoxDecoration(
      color: BioTheme.danger.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: BioTheme.danger.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: BioTheme.danger),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: BioTheme.textPrimary),
          ),
        ),
        if (action != null)
          TextButton(onPressed: action, child: const Text('Reintentar')),
      ],
    ),
  );
}

/// Pin redondo con el ícono y el color del grupo de la especie.
class _SpecimenPin extends StatelessWidget {
  const _SpecimenPin({required this.group, this.size = 34});
  final SpeciesGroup group;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(group.color, Colors.white, .25)!, group.color],
      ),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Icon(group.icon, size: size * .55, color: BioTheme.backgroundDeep),
  );
}

/// Varios ejemplares cercanos: el color es el del grupo más común.
class _ClusterPin extends StatelessWidget {
  const _ClusterPin({required this.count, required this.color, this.size = 42});
  final int count;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: .35),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BioTheme.backgroundDeep,
        border: Border.all(color: color, width: 2.5),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * .32,
        ),
      ),
    ),
  );
}

class _AnimalPin extends StatelessWidget {
  const _AnimalPin({this.size = 34});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFF4A259),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Icon(Icons.pets_rounded, size: size * .5, color: Colors.white),
  );
}

class _UserDot extends StatelessWidget {
  const _UserDot();
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF3D8BFD).withValues(alpha: .22),
    ),
    child: Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF3D8BFD),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.marker, required this.label, this.detail});
  final Widget marker;
  final String label;
  final String? detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        SizedBox(width: 40, child: Center(child: marker)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        if (detail != null)
          Text(
            detail!,
            style: const TextStyle(color: BioTheme.textMuted, fontSize: 12.5),
          ),
      ],
    ),
  );
}
