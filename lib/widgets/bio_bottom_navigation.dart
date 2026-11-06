import 'package:flutter/material.dart';
import '../navigation/app_routes.dart';
import '../theme/bio_theme.dart';
import 'glass/deep_frost_glass.dart';
import 'glass/glass_icon.dart';

enum BioTab { home, map, identify, gamification, profile, explore }

class BioBottomNavigation extends StatelessWidget {
  const BioBottomNavigation({super.key, this.activeTab});
  final BioTab? activeTab;
  @override
  Widget build(BuildContext context) => DeepFrostGlass(
    borderRadius: 30,
    child: Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _item(
              context,
              BioTab.home,
              'Inicio',
              Icons.home_outlined,
              AppRoutes.home,
            ),
            _item(
              context,
              BioTab.map,
              'Mapa',
              Icons.map_outlined,
              AppRoutes.map,
            ),
            _item(
              context,
              BioTab.identify,
              'Cámara',
              Icons.camera_alt_outlined,
              AppRoutes.identify,
            ),
            _item(
              context,
              BioTab.gamification,
              'Gamificación',
              Icons.emoji_events_outlined,
              AppRoutes.gamification,
            ),
            _item(
              context,
              BioTab.profile,
              'Perfil',
              Icons.person_outline,
              AppRoutes.profile,
            ),
          ],
        ),
      ),
    ),
  );
  Widget _item(
    BuildContext context,
    BioTab tab,
    String label,
    IconData icon,
    String route,
  ) {
    final selected = activeTab == tab;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => AppRoutes.goTo(context, route),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: selected
                        ? GlassIcon(
                            key: ValueKey(tab),
                            icon: icon,
                            size: 42,
                            iconSize: 24,
                          )
                        : SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(icon, color: BioTheme.textSecondary),
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 10,
                      color: selected ? BioTheme.lime : BioTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
