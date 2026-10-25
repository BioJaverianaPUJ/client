import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_theme.dart';
import 'bio_pressable.dart';
import 'glass/deep_frost_glass.dart';
import 'glass/glass_icon.dart';

enum BioTab { home, explore, identify, profile }

class BioBottomNavigation extends StatelessWidget {
  const BioBottomNavigation({super.key, this.activeTab});

  final BioTab? activeTab;

  @override
  Widget build(BuildContext context) {
    return DeepFrostGlass(
      borderRadius: 30,
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            label: 'Inicio',
            icon: BioIcons.homeOutline,
            active: activeTab == BioTab.home,
            onTap: () => AppRoutes.goTo(context, AppRoutes.home),
          ),
          _NavItem(
            label: 'Explorar',
            icon: BioIcons.compassOutline,
            active: activeTab == BioTab.explore,
            onTap: () => AppRoutes.goTo(context, AppRoutes.explore),
          ),
          _NavItem(
            label: 'Identificar',
            icon: BioIcons.cameraOutline,
            active: activeTab == BioTab.identify,
            onTap: () => AppRoutes.goTo(context, AppRoutes.identify),
          ),
          _NavItem(
            label: 'Perfil',
            icon: BioIcons.accountOutline,
            active: activeTab == BioTab.profile,
            onTap: () => AppRoutes.goTo(context, AppRoutes.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 61, minHeight: 63),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              GlassIcon(icon: icon, size: 40, iconSize: 18)
            else
              Icon(icon, size: 22, color: const Color(0xFFD0DBD5)),
            SizedBox(height: active ? 2 : 4),
            Text(
              label,
              style: TextStyle(
                color: active ? BioTheme.lime : const Color(0xFFD7E1DC),
                fontSize: 8.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
