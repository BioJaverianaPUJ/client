import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/bio_category.dart';
import '../models/species.dart';
import '../navigation/app_routes.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_text_styles.dart';
import '../theme/bio_theme.dart';
import '../widgets/bio_action_card.dart';
import '../widgets/bio_badge.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/bio_filter_chip.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/glass/glass_icon.dart';
import '../widgets/glass/soft_frost_glass.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  BioCategory _category = BioCategory.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() => _category = BioCategory.all);
  }

  @override
  Widget build(BuildContext context) {
    final results = MockData.species
        .where((s) => _category.includes(s.category) && s.matches(_search.text))
        .toList();

    return BioScreen(
      activeTab: BioTab.explore,
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/tree.png',
          color: BioTheme.botanical,
          opacity: 0.13,
          right: -280,
          bottom: -80,
          width: 620,
          height: 1080,
          alignment: Alignment.bottomCenter,
        ),
      ],
      children: [
        const BioIntro(
          eyebrow: 'EXPLORA EL CAMPUS',
          title: 'Descubre la',
          accent: 'biodiversidad.',
          description: 'Busca especies, explora categorías y conoce la vida '
              'que comparte contigo el campus.',
          descriptionWidthFactor: 0.9,
        ),
        const SizedBox(height: 25),
        SoftFrostGlass(
          borderRadius: 24,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: Row(
            children: [
              Icon(BioIcons.magnify, size: 21, color: BioTheme.limeSoft),
              const SizedBox(width: 11),
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  autocorrect: false,
                  cursorColor: BioTheme.lime,
                  style: const TextStyle(
                    color: BioTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Buscar una especie...',
                    hintStyle: TextStyle(
                      color: BioTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (_search.text.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(_search.clear),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      BioIcons.closeCircleOutline,
                      size: 19,
                      color: BioTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const BioSectionHeader(title: 'CATEGORÍAS', top: 27),
        BioFilterBar(
          selected: _category,
          tinted: true,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: 25),
        _DiscoveryCard(onTap: () => AppRoutes.goTo(context, AppRoutes.map)),
        Padding(
          padding: const EdgeInsets.only(top: 31, bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ESPECIES', style: BioTextStyles.sectionEyebrow),
                  const SizedBox(height: 5),
                  Text(
                    '${results.length} '
                    '${results.length == 1 ? 'resultado' : 'resultados'}',
                    style: const TextStyle(
                      color: BioTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _reset,
                child: const Text(
                  'Ver todas',
                  style: TextStyle(
                    color: BioTheme.limeSoft,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final species in results) ...[
          _SpeciesCard(species: species),
          const SizedBox(height: 10),
        ],
        if (results.isEmpty) _EmptyResults(onReset: _reset),
        const SizedBox(height: 15),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.cameraOutline,
            size: 46,
            iconSize: 21,
            strong: true,
          ),
          eyebrow: '¿VES ALGO INTERESANTE?',
          title: 'Identifica una especie',
          description: 'Usa tu cámara para comenzar.',
          trailing: Icon(
            BioIcons.arrowRight,
            size: 21,
            color: BioTheme.limeSoft,
          ),
          onTap: () => AppRoutes.goTo(context, AppRoutes.identify),
        ),
      ],
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      child: SoftFrostGlass(
        borderRadius: 34,
        minHeight: 225,
        padding: const EdgeInsets.fromLTRB(21, 20, 21, 17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassIcon(
                  icon: BioIcons.mapMarkerRadiusOutline,
                  size: 45,
                  iconSize: 20,
                ),
                const BioBadge(label: 'CAMPUS'),
              ],
            ),
            const SizedBox(height: 18),
            const Text.rich(
              TextSpan(
                text: 'Explora lo que\n',
                children: [
                  TextSpan(
                    text: 'tienes cerca.',
                    style: TextStyle(color: BioTheme.lime),
                  ),
                ],
              ),
              style: TextStyle(
                color: BioTheme.textPrimary,
                fontSize: 25,
                height: 28 / 25,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            const FractionallySizedBox(
              widthFactor: 0.78,
              child: Text(
                'Recorre el campus y descubre especies registradas en '
                'diferentes zonas.',
                style: TextStyle(
                  color: BioTheme.textSecondary,
                  fontSize: 11.5,
                  height: 17 / 11.5,
                ),
              ),
            ),
            const SizedBox(height: 17),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ver en el mapa',
                  style: TextStyle(
                    color: BioTheme.limeSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GlassIcon(
                  icon: BioIcons.arrowRight,
                  size: 44,
                  iconSize: 20,
                  strong: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesCard extends StatelessWidget {
  const _SpeciesCard({required this.species});

  final Species species;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: () {},
      child: SoftFrostGlass(
        borderRadius: 27,
        minHeight: 92,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlassIcon(icon: species.icon, size: 48, iconSize: 21),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    species.commonName,
                    style: const TextStyle(
                      color: BioTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    species.scientificName,
                    style: const TextStyle(
                      color: BioTheme.limeSoft,
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        BioIcons.mapMarkerOutline,
                        size: 12,
                        color: BioTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        species.zone,
                        style: const TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(BioIcons.chevronRight, size: 22, color: BioTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SoftFrostGlass(
      borderRadius: 30,
      minHeight: 220,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassIcon(icon: BioIcons.leafOff, size: 50, iconSize: 22),
            const SizedBox(height: 15),
            const Text(
              'No encontramos especies',
              style: TextStyle(
                color: BioTheme.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const FractionallySizedBox(
              widthFactor: 0.8,
              child: Text(
                'Prueba otra búsqueda o selecciona una categoría diferente.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BioTheme.textSecondary,
                  fontSize: 11,
                  height: 16 / 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onReset,
              child: const Text(
                'Limpiar filtros',
                style: TextStyle(
                  color: BioTheme.lime,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
