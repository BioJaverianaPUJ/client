import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/bio_category.dart';
import '../models/observation.dart';
import '../navigation/app_routes.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_text_styles.dart';
import '../theme/bio_theme.dart';
import '../theme/glass_tokens.dart';
import '../widgets/bio_action_card.dart';
import '../widgets/bio_filter_chip.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/bio_stat_card.dart';
import '../widgets/glass/glass_icon.dart';
import '../widgets/glass/soft_frost_glass.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  BioCategory _category = BioCategory.all;

  @override
  Widget build(BuildContext context) {
    final observations = MockData.observations
        .where((observation) => _category.includes(observation.category))
        .toList();

    return BioScreen(
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/bare_tree.png',
          color: BioTheme.limeSoft,
          opacity: 0.10,
          right: -15,
          bottom: -35,
          width: 390,
          height: 720,
          alignment: Alignment.bottomCenter,
        ),
      ],
      children: [
        const BioIntro(
          eyebrow: 'MIS OBSERVACIONES',
          title: 'Tu biodiversidad,',
          accent: 'registrada.',
          description: 'Guarda tus encuentros con la naturaleza y construye '
              'tu propio registro de biodiversidad del campus.',
        ),
        const SizedBox(height: 27),
        BioStatRow(
          children: [
            BioStatCard(
              icon: BioIcons.bookmarkOutline,
              value: '${MockData.recordsCount}',
              label: 'Registros',
            ),
            BioStatCard(
              icon: BioIcons.leaf,
              value: '${MockData.speciesCount}',
              label: 'Especies',
            ),
            BioStatCard(
              icon: BioIcons.mapMarkerOutline,
              value: '${MockData.zonesCount}',
              label: 'Zonas',
            ),
          ],
        ),
        const SizedBox(height: 13),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.cameraOutline,
            size: 54,
            iconSize: 23,
            strong: true,
          ),
          eyebrow: 'NUEVO REGISTRO',
          title: 'Añade una observación',
          description: 'Identifica y registra una especie.',
          titleStyle: BioTextStyles.cardTitle.copyWith(fontSize: 15),
          descriptionStyle:
              BioTextStyles.cardDescription.copyWith(fontSize: 9.5),
          borderRadius: 32,
          minHeight: 122,
          padding: const EdgeInsets.all(16),
          trailing: Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BioTheme.lime,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              BioIcons.arrowRight,
              size: 20,
              color: BioTheme.backgroundDeep,
            ),
          ),
          onTap: () => AppRoutes.goTo(context, AppRoutes.identify),
        ),
        BioSectionHeader(
          title: 'TUS REGISTROS',
          top: 28,
          trailing: Text(
            '${observations.length}',
            style: const TextStyle(
              color: BioTheme.limeSoft,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        BioFilterBar(
          selected: _category,
          iconSize: 15,
          onSelected: (category) => setState(() => _category = category),
        ),
        const SizedBox(height: 17),
        for (final (index, observation) in observations.indexed) ...[
          if (index > 0) const SizedBox(height: 11),
          _ObservationCard(observation: observation, highlighted: index == 0),
        ],
        const BioSectionHeader(title: 'DESCUBRE MÁS'),
        BioActionCard(
          material: GlassMaterial.frosted,
          leading: GlassIcon(
            icon: BioIcons.mapOutline,
            size: 52,
            iconSize: 22,
            strong: true,
          ),
          eyebrow: 'MAPA DEL CAMPUS',
          title: 'Explora tus observaciones',
          description: 'Descubre en qué zonas has registrado biodiversidad.',
          borderRadius: 32,
          minHeight: 125,
          trailing: Icon(
            BioIcons.arrowRight,
            size: 21,
            color: BioTheme.limeSoft,
          ),
          onTap: () => AppRoutes.goTo(context, AppRoutes.map),
        ),
      ],
    );
  }
}

class _ObservationCard extends StatelessWidget {
  const _ObservationCard({
    required this.observation,
    required this.highlighted,
  });

  final Observation observation;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: () {},
      child: SoftFrostGlass(
        borderRadius: 30,
        minHeight: 105,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            GlassIcon(
              icon: observation.icon,
              size: 52,
              iconSize: 21,
              strong: highlighted,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              observation.commonName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BioTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              observation.scientificName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BioTheme.limeSoft,
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        observation.date,
                        style: const TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        BioIcons.mapMarkerOutline,
                        size: 13,
                        color: BioTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          observation.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: BioTheme.textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(218, 230, 119, 0.055),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromRGBO(218, 230, 119, 0.12),
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(BioIcons.check, size: 10, color: BioTheme.lime),
                            const SizedBox(width: 3),
                            const Text(
                              'Identificada',
                              style: TextStyle(
                                color: BioTheme.limeSoft,
                                fontSize: 6.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(BioIcons.chevronRight, size: 20, color: BioTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
