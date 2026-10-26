import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_theme.dart';
import '../widgets/bio_badge.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/glass/glass_icon.dart';
import '../widgets/glass/soft_frost_glass.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void goTo(String route) => AppRoutes.goTo(context, route);

    return BioScreen(
      activeTab: BioTab.home,
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/radiant_column.png',
          color: BioTheme.botanical,
          opacity: 0.19,
          right: -225,
          bottom: -55,
          width: 530,
          height: 980,
          alignment: Alignment.bottomCenter,
        ),
      ],
      children: [
        const BioIntro(
          top: 19,
          eyebrow: 'BIODIVERSIDAD JAVERIANA',
          title: 'Explora la vida',
          accent: 'que te rodea.',
          description: 'Descubre especies, registra observaciones y conoce la '
              'biodiversidad que habita en nuestro campus.',
          descriptionWidthFactor: 0.88,
        ),
        const SizedBox(height: 28),
        _HeroCard(onTap: () => goTo(AppRoutes.explore)),
        const BioSectionHeader(title: 'ACCESOS RÁPIDOS'),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: BioIcons.mapOutline,
                title: 'Mapa',
                description: 'Explora el campus',
                onTap: () => goTo(AppRoutes.map),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: BioIcons.cameraOutline,
                title: 'Identificar',
                description: 'Reconoce una especie',
                onTap: () => goTo(AppRoutes.identify),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: BioIcons.flowerOutline,
                title: 'Especies',
                description: 'Consulta el catálogo',
                onTap: () => goTo(AppRoutes.explore),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: BioIcons.bookmarkOutline,
                title: 'Registros',
                description: 'Tus observaciones',
                onTap: () => goTo(AppRoutes.records),
              ),
            ),
          ],
        ),
        const BioSectionHeader(title: 'DESCUBRE HOY'),
        _DiscoveryCard(onTap: () => goTo(AppRoutes.explore)),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      child: SoftFrostGlass(
        borderRadius: 36,
        minHeight: 245,
        padding: const EdgeInsets.fromLTRB(22, 21, 22, 17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassIcon(icon: BioIcons.leaf, size: 45, iconSize: 20),
                const BioBadge(label: 'EXPLORAR'),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Biodiversidad\ndel campus',
              style: TextStyle(
                color: BioTheme.textPrimary,
                fontSize: 27,
                height: 30 / 27,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 9),
            const FractionallySizedBox(
              widthFactor: 0.77,
              child: Text(
                'Conoce las especies que comparten este espacio contigo.',
                style: TextStyle(
                  color: BioTheme.textSecondary,
                  fontSize: 12,
                  height: 17 / 12,
                ),
              ),
            ),
            const SizedBox(height: 19),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Comenzar a explorar',
                  style: TextStyle(
                    color: BioTheme.limeSoft,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GlassIcon(
                  icon: BioIcons.arrowRight,
                  size: 46,
                  iconSize: 21,
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

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      child: SoftFrostGlass(
        borderRadius: 29,
        height: 155,
        padding: const EdgeInsets.all(15),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassIcon(icon: icon),
                const SizedBox(height: 17),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BioTheme.textMuted,
                    fontSize: 10.5,
                    height: 14 / 10.5,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 1,
              top: 2,
              child: Icon(
                BioIcons.arrowTopRight,
                size: 16,
                color: BioTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
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
        borderRadius: 30,
        minHeight: 145,
        padding: const EdgeInsets.all(19),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 107),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BioDot(),
                          SizedBox(width: 7),
                          Text(
                            'ESPECIE DESTACADA',
                            style: TextStyle(
                              color: BioTheme.limeSoft,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Hay mucho por descubrir',
                        style: TextStyle(
                          color: BioTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Cada rincón del campus puede esconder una nueva '
                        'observación.',
                        style: TextStyle(
                          color: BioTheme.textSecondary,
                          fontSize: 10.5,
                          height: 15 / 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: GlassIcon(icon: BioIcons.arrowRight, strong: true),
            ),
          ],
        ),
      ),
    );
  }
}
