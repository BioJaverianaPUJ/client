import 'package:flutter/material.dart';

import '../navigation/app_routes.dart';
import '../theme/bio_icons.dart';
import '../theme/bio_theme.dart';
import 'bio_pressable.dart';
import 'glass/deep_frost_glass.dart';

class BioTopBar extends StatelessWidget {
  const BioTopBar({super.key, this.showProfileButton = true});

  final bool showProfileButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          Expanded(
            child: Transform.translate(
              offset: const Offset(-8, 0),
              child: Image.asset(
                'assets/BioJaveriana.png',
                height: 78,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                color: BioTheme.lime,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          if (showProfileButton)
            BioPressable(
              onTap: () => AppRoutes.goTo(context, AppRoutes.profile),
              child: DeepFrostGlass(
                borderRadius: 18,
                width: 46,
                height: 46,
                child: Center(
                  child: Icon(
                    BioIcons.accountOutline,
                    size: 21,
                    color: BioTheme.lime,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
