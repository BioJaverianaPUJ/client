import 'package:flutter/material.dart';

import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../../theme/glass_tokens.dart';
import '../bio_pressable.dart';
import 'glass_icon.dart';
import 'liquid_glass.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.title,
    this.onPressed,
    this.icon,
    this.iconSize = 47,
    this.height = 60,
    this.borderRadius = BioTheme.buttonRadius,
    this.material = GlassMaterial.regular,
    this.contentPadding = const EdgeInsets.fromLTRB(22, 0, 62, 0),
    this.showIcon = true,
    this.loading = false,
  });

  final String title;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double iconSize;
  final double height;
  final double borderRadius;
  final GlassMaterial material;
  final EdgeInsetsGeometry contentPadding;
  final bool showIcon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: loading ? null : onPressed ?? () {},
      pressedOpacity: 0.84,
      pressedScale: 0.995,
      child: LiquidGlass(
        material: material,
        borderRadius: borderRadius,
        width: double.infinity,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color.fromRGBO(0, 23, 20, 0.24)),
            Padding(
              padding: contentPadding,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BioTheme.lime,
                        ),
                      )
                    : Text(
                        title,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: BioTheme.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.15,
                        ),
                      ),
              ),
            ),
            if (showIcon)
              Positioned(
                right: 7,
                top: (height - iconSize) / 2,
                child: GlassIcon(
                  icon: icon ?? BioIcons.arrowRight,
                  size: iconSize,
                  iconSize: (iconSize * 0.47).roundToDouble(),
                  strong: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
