import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../navigation/app_routes.dart';
import '../state/app_scope.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_theme.dart';
import '../widgets/bio_action_card.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/bio_stat_card.dart';
import '../widgets/glass/deep_frost_glass.dart';
import '../widgets/glass/glass_icon.dart';
import '../widgets/glass/soft_frost_glass.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppScope.watch(context).user;
    void goTo(String route) => AppRoutes.goTo(context, route);
    final chevron = Icon(
      BioIcons.chevronRight,
      size: 22,
      color: BioTheme.textMuted,
    );

    return BioScreen(
      activeTab: BioTab.profile,
      showProfileButton: false,
      decorations: const [
        BioIllustration(
          asset: 'assets/illustrations/layered_birds.png',
          color: BioTheme.limeSoft,
          opacity: 0.13,
          right: 2,
          top: 90,
          width: 175,
          height: 135,
        ),
        BioIllustration(
          asset: 'assets/illustrations/treeline_reflection.png',
          color: BioTheme.limeSoft,
          opacity: 0.10,
          left: -25,
          right: -25,
          bottom: 45,
          height: 270,
          fit: BoxFit.fitHeight,
          alignment: Alignment.bottomCenter,
        ),
      ],
      children: [
        const BioIntro(
          eyebrow: 'TU PERFIL',
          title: 'Tu huella en',
          accent: 'el campus.',
          description: 'Consulta tus observaciones, descubre tu progreso y '
              'continúa explorando la biodiversidad Javeriana.',
        ),
        const SizedBox(height: 28),
        _ProfileCard(
          name: user?.fullName ?? 'Cargando perfil…',
          username: user == null ? null : '@${user.username}',
        ),
        const SizedBox(height: 13),
        BioStatRow(
          children: [
            BioStatCard(
              icon: BioIcons.bookmarkOutline,
              value: '${MockData.recordsCount}',
              label: 'Registros',
              height: 128,
              onTap: () => goTo(AppRoutes.records),
            ),
            BioStatCard(
              icon: BioIcons.leaf,
              value: '${MockData.speciesCount}',
              label: 'Especies',
              height: 128,
              onTap: () => goTo(AppRoutes.explore),
            ),
            BioStatCard(
              icon: BioIcons.mapMarkerOutline,
              value: '${MockData.zonesCount}',
              label: 'Zonas',
              height: 128,
              onTap: () => goTo(AppRoutes.map),
            ),
          ],
        ),
        const BioSectionHeader(title: 'TU PROGRESO'),
        _ProgressCard(onOpenMap: () => goTo(AppRoutes.map)),
        const BioSectionHeader(title: 'TU ACTIVIDAD'),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.bookmarkOutline,
            size: 46,
            iconSize: 20,
            strong: true,
          ),
          title: 'Mis registros',
          description: 'Consulta todas tus observaciones.',
          borderRadius: 29,
          minHeight: 103,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          trailing: chevron,
          onTap: () => goTo(AppRoutes.records),
        ),
        const SizedBox(height: 10),
        BioActionCard(
          leading: GlassIcon(icon: BioIcons.mapOutline, size: 46, iconSize: 20),
          title: 'Mapa del campus',
          description: 'Explora dónde has encontrado especies.',
          borderRadius: 29,
          minHeight: 103,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          trailing: chevron,
          onTap: () => goTo(AppRoutes.map),
        ),
        const SizedBox(height: 10),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.compassOutline,
            size: 46,
            iconSize: 20,
          ),
          title: 'Explorar biodiversidad',
          description: 'Descubre animales, plantas y árboles.',
          borderRadius: 29,
          minHeight: 103,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          trailing: chevron,
          onTap: () => goTo(AppRoutes.explore),
        ),
        const BioSectionHeader(title: 'PREFERENCIAS'),
        SoftFrostGlass(
          borderRadius: 31,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            children: [
              _PreferenceRow(
                icon: BioIcons.bellOutline,
                title: 'Notificaciones',
                description: 'Actividad y nuevos descubrimientos',
              ),
              const _PreferenceDivider(),
              _PreferenceRow(
                icon: BioIcons.accountCogOutline,
                title: 'Cuenta',
                description: user?.email ?? 'Información y preferencias',
              ),
              const _PreferenceDivider(),
              _PreferenceRow(
                icon: BioIcons.informationOutline,
                title: 'Acerca de BioJaveriana',
                description: 'Proyecto y biodiversidad del campus',
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        BioPressable(
          onTap: () => AppRoutes.logout(context),
          child: DeepFrostGlass(
            borderRadius: 28,
            height: 69,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(BioIcons.logout, size: 20, color: BioTheme.lime),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Cerrar sesión',
                    style: TextStyle(
                      color: BioTheme.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  BioIcons.arrowRight,
                  size: 18,
                  color: BioTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, this.username});

  final String name;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return DeepFrostGlass(
      borderRadius: 34,
      minHeight: 132,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 73,
            height: 73,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color.fromRGBO(218, 230, 119, 0.09),
              borderRadius: BorderRadius.circular(29),
              border: Border.all(
                color: const Color.fromRGBO(218, 230, 119, 0.24),
              ),
            ),
            child: Container(
              width: 59,
              height: 59,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BioTheme.lime,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                BioIcons.accountOutline,
                size: 37,
                color: BioTheme.backgroundDeep,
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPLORADOR JAVERIANO',
                  style: TextStyle(
                    color: BioTheme.limeSoft,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    maxLines: 1,
                    style: const TextStyle(
                      color: BioTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      username == null
                          ? BioIcons.mapMarkerOutline
                          : BioIcons.at,
                      size: 13,
                      color: BioTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        username ?? MockData.userCampus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BioPressable(
            onTap: () {},
            child: Container(
              width: 39,
              height: 39,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.035),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color.fromRGBO(225, 238, 228, 0.10),
                ),
              ),
              child: Icon(
                BioIcons.pencilOutline,
                size: 18,
                color: BioTheme.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.onOpenMap});

  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    const progress = MockData.explorationProgress;

    return SoftFrostGlass(
      borderRadius: 31,
      minHeight: 184,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassIcon(
                icon: BioIcons.compassOutline,
                size: 49,
                iconSize: 21,
                strong: true,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXPLORACIÓN DEL CAMPUS',
                      style: TextStyle(
                        color: BioTheme.limeSoft,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Sigue descubriendo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: BioTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: BioTheme.lime,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const FractionallySizedBox(
                      widthFactor: 0.91,
                      child: Text(
                        'Has explorado ${MockData.zonesCount} zonas con '
                        'registros de biodiversidad.',
                        style: TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 9.5,
                          height: 14 / 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: const SizedBox(
              height: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: Color.fromRGBO(255, 255, 255, 0.07)),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: ColoredBox(color: BioTheme.lime),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '${MockData.zonesCount} zonas exploradas',
                style: TextStyle(color: BioTheme.textMuted, fontSize: 8.5),
              ),
              GestureDetector(
                onTap: onOpenMap,
                child: Row(
                  children: [
                    const Text(
                      'Ver mapa',
                      style: TextStyle(
                        color: BioTheme.lime,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(BioIcons.arrowRight, size: 14, color: BioTheme.lime),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: () {},
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.035),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: const Color.fromRGBO(225, 238, 228, 0.10),
                ),
              ),
              child: Icon(icon, size: 18, color: BioTheme.lime),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: BioTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: BioTheme.textMuted,
                      fontSize: 8.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(BioIcons.chevronRight, size: 20, color: BioTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PreferenceDivider extends StatelessWidget {
  const _PreferenceDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 51),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: Color.fromRGBO(225, 238, 228, 0.07)),
      ),
    );
  }
}
