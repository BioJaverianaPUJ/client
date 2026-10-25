import '../theme/bio_icons.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/bio_category.dart';
import '../models/campus_location.dart';
import '../navigation/app_routes.dart';
import '../theme/bio_text_styles.dart';
import '../theme/bio_theme.dart';
import '../widgets/bio_action_card.dart';
import '../widgets/bio_badge.dart';
import '../widgets/bio_filter_chip.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/bio_stat_card.dart';
import '../widgets/glass/deep_frost_glass.dart';
import '../widgets/glass/glass_icon.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  BioCategory _category = BioCategory.all;
  CampusLocation? _selected;

  void _filter(BioCategory category) {
    setState(() {
      _category = category;
      _selected = null;
    });
  }

  void _toggle(CampusLocation location) {
    setState(() => _selected = _selected?.id == location.id ? null : location);
  }

  @override
  Widget build(BuildContext context) {
    final locations = MockData.campusLocations
        .where((location) => _category.includes(location.category))
        .toList();
    final selected = _selected;

    return BioScreen(
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/scattered_birds.png',
          color: BioTheme.limeSoft,
          opacity: 0.14,
          right: -145,
          top: 50,
          width: 520,
          height: 250,
        ),
      ],
      children: [
        const BioIntro(
          eyebrow: 'MAPA DEL CAMPUS',
          title: 'Explora el',
          accent: 'campus.',
          description: 'Descubre las zonas donde se han registrado especies '
              'y encuentra biodiversidad cerca de ti.',
          descriptionWidthFactor: 0.87,
        ),
        const BioSectionHeader(title: 'FILTRAR MAPA', top: 27),
        BioFilterBar(selected: _category, onSelected: _filter),
        const SizedBox(height: 24),
        _CampusMap(
          locations: locations,
          selectedId: selected?.id,
          onMarkerTap: _toggle,
        ),
        const SizedBox(height: 13),
        if (selected != null)
          BioActionCard(
            leading: GlassIcon(
              icon: selected.icon,
              size: 52,
              iconSize: 22,
              strong: true,
            ),
            eyebrow: 'ZONA SELECCIONADA',
            title: selected.name,
            description: selected.subtitle,
            titleStyle: BioTextStyles.cardTitle.copyWith(fontSize: 15),
            minHeight: 108,
            padding: const EdgeInsets.all(15),
            trailing: Icon(
              BioIcons.arrowRight,
              size: 21,
              color: BioTheme.limeSoft,
            ),
            onTap: () => AppRoutes.goTo(context, AppRoutes.explore),
          )
        else
          BioActionCard(
            leading: GlassIcon(
              icon: BioIcons.mapMarkerRadiusOutline,
              size: 48,
              iconSize: 21,
            ),
            eyebrow: 'EXPLORA POR ZONAS',
            title: 'Descubre qué hay cerca',
            description: 'Selecciona un marcador para consultar la '
                'biodiversidad registrada en esa zona.',
            minHeight: 110,
          ),
        const BioSectionHeader(title: 'BIODIVERSIDAD DEL CAMPUS'),
        BioStatRow(
          children: [
            BioStatCard(
              icon: BioIcons.paw,
              value: '${MockData.campusAnimals}',
              label: 'Animales',
              height: 132,
              valueStyle: BioTextStyles.statValue.copyWith(fontSize: 24),
              onTap: () => _filter(BioCategory.animals),
            ),
            BioStatCard(
              icon: BioIcons.flowerOutline,
              value: '${MockData.campusPlants}',
              label: 'Plantas',
              height: 132,
              valueStyle: BioTextStyles.statValue.copyWith(fontSize: 24),
              onTap: () => _filter(BioCategory.plants),
            ),
            BioStatCard(
              icon: BioIcons.treeOutline,
              value: '${MockData.campusTrees}',
              label: 'Árboles',
              height: 132,
              valueStyle: BioTextStyles.statValue.copyWith(fontSize: 24),
              onTap: () => _filter(BioCategory.trees),
            ),
          ],
        ),
        const SizedBox(height: 25),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.compassOutline,
            size: 46,
            iconSize: 21,
            strong: true,
          ),
          eyebrow: 'CATÁLOGO',
          title: 'Explora todas las especies',
          description: 'Consulta la biodiversidad del campus.',
          trailing: Icon(
            BioIcons.arrowRight,
            size: 21,
            color: BioTheme.limeSoft,
          ),
          onTap: () => AppRoutes.goTo(context, AppRoutes.explore),
        ),
      ],
    );
  }
}

class _CampusMap extends StatelessWidget {
  const _CampusMap({
    required this.locations,
    required this.selectedId,
    required this.onMarkerTap,
  });

  static const double _height = 470;

  final List<CampusLocation> locations;
  final String? selectedId;
  final ValueChanged<CampusLocation> onMarkerTap;

  @override
  Widget build(BuildContext context) {
    return DeepFrostGlass(
      borderRadius: 36,
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              ..._drawing(width),
              Positioned(
                left: 19,
                top: 19,
                right: 19,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      BioIcons.mapMarkerOutline,
                      size: 19,
                      color: BioTheme.limeSoft,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PONTIFICIA UNIVERSIDAD JAVERIANA',
                            style: TextStyle(
                              color: BioTheme.textMuted,
                              fontSize: 6.7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Campus Bogotá',
                            style: TextStyle(
                              color: BioTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const BioBadge(label: 'CAMPUS', compact: true),
                  ],
                ),
              ),
              for (final location in locations)
                Positioned(
                  left: width * location.left - 23,
                  top: _height * location.top - 23,
                  child: _Marker(
                    location: location,
                    active: location.id == selectedId,
                    onTap: () => onMarkerTap(location),
                  ),
                ),
              Positioned(
                right: 19,
                top: 73,
                child: Column(
                  children: [
                    const Text(
                      'N',
                      style: TextStyle(
                        color: BioTheme.textMuted,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Icon(
                      BioIcons.navigationVariant,
                      size: 20,
                      color: BioTheme.limeSoft,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 17,
                bottom: 18,
                child: BioPressable(
                  onTap: () {},
                  child: DeepFrostGlass(
                    width: 47,
                    height: 47,
                    borderRadius: 18,
                    child: Center(
                      child: Icon(
                        BioIcons.crosshairsGps,
                        size: 21,
                        color: BioTheme.lime,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 19,
                bottom: 28,
                child: Row(
                  children: [
                    Icon(
                      BioIcons.gestureTap,
                      size: 15,
                      color: BioTheme.limeSoft,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Toca un marcador para explorar',
                      style: TextStyle(
                        color: BioTheme.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _drawing(double width) {
    return [
      _area(left: -30, top: 125, width: 180, height: 130, opacity: 0.045),
      _area(
        left: width + 25 - 170,
        top: 210,
        width: 170,
        height: 145,
        opacity: 0.04,
      ),
      _area(
        left: 70,
        top: _height + 30 - 130,
        width: 185,
        height: 130,
        opacity: 0.035,
      ),
      _road(
        left: -55,
        top: 205,
        width: 440,
        height: 52,
        stroke: 1.2,
        opacity: 0.085,
        degrees: -17,
      ),
      _road(
        left: -20,
        top: 330,
        width: 400,
        height: 42,
        stroke: 1,
        opacity: 0.065,
        degrees: 12,
      ),
      _line(left: width * 0.47, top: 70, height: 390, opacity: 0.07, degrees: 10),
      _line(
        left: width * 0.70,
        top: 105,
        height: 340,
        opacity: 0.055,
        degrees: -21,
      ),
      _building(
        left: 38,
        top: 145,
        width: 78,
        height: 46,
        radius: 8,
        fill: 0.055,
        border: 0.07,
        degrees: -8,
      ),
      _building(
        left: width - 34 - 102,
        top: 170,
        width: 102,
        height: 62,
        radius: 9,
        fill: 0.05,
        border: 0.065,
        degrees: 7,
      ),
      _building(
        left: 65,
        top: _height - 72 - 92,
        width: 65,
        height: 92,
        radius: 9,
        fill: 0.045,
        border: 0.06,
        degrees: 8,
      ),
      _building(
        left: width - 72 - 66,
        top: _height - 92 - 65,
        width: 66,
        height: 65,
        radius: 9,
        fill: 0.045,
        border: 0.06,
        degrees: -10,
      ),
      _building(
        left: width * 0.46,
        top: 130,
        width: 48,
        height: 70,
        radius: 8,
        fill: 0.04,
        degrees: 4,
      ),
      _building(
        left: width * 0.42,
        top: _height - 90 - 42,
        width: 58,
        height: 42,
        radius: 8,
        fill: 0.04,
        degrees: -5,
      ),
      _tree(left: 35, top: 250),
      _tree(left: 92, top: 275),
      _tree(left: width - 47 - 16, top: 290),
      _tree(left: 155, top: _height - 60 - 16),
      _tree(left: width - 130 - 16, top: _height - 47 - 16),
      _tree(left: width - 35 - 16, top: _height - 150 - 16),
    ];
  }

  static Widget _area({
    required double left,
    required double top,
    required double width,
    required double height,
    required double opacity,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.fromRGBO(144, 176, 105, opacity),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }

  static Widget _road({
    required double left,
    required double top,
    required double width,
    required double height,
    required double stroke,
    required double opacity,
    required double degrees,
  }) {
    final side = BorderSide(
      color: Color.fromRGBO(216, 235, 221, opacity),
      width: stroke,
    );
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: side, bottom: side)),
        ),
      ),
    );
  }

  static Widget _line({
    required double left,
    required double top,
    required double height,
    required double opacity,
    required double degrees,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: 1,
      height: height,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: ColoredBox(color: Color.fromRGBO(216, 235, 221, opacity)),
      ),
    );
  }

  static Widget _building({
    required double left,
    required double top,
    required double width,
    required double height,
    required double radius,
    required double fill,
    double? border,
    required double degrees,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: degrees * math.pi / 180,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.fromRGBO(177, 203, 190, fill),
            borderRadius: BorderRadius.circular(radius),
            border: border == null
                ? null
                : Border.all(
                    color: Color.fromRGBO(216, 235, 221, border),
                    width: 0.8,
                  ),
          ),
        ),
      ),
    );
  }

  static Widget _tree({required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      width: 16,
      height: 16,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color.fromRGBO(167, 196, 123, 0.065),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.location,
    required this.active,
    required this.onTap,
  });

  final CampusLocation location;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? const Color.fromRGBO(218, 230, 119, 0.16)
              : const Color.fromRGBO(198, 220, 174, 0.07),
          border: Border.all(
            color: active
                ? const Color.fromRGBO(218, 230, 119, 0.34)
                : const Color.fromRGBO(218, 237, 207, 0.13),
          ),
        ),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? BioTheme.lime
                : const Color.fromRGBO(9, 55, 48, 0.95),
            border: Border.all(
              color: active
                  ? BioTheme.lime
                  : const Color.fromRGBO(221, 238, 210, 0.14),
            ),
          ),
          child: Icon(
            location.icon,
            size: 18,
            color: active ? BioTheme.backgroundDeep : BioTheme.lime,
          ),
        ),
      ),
    );
  }
}
