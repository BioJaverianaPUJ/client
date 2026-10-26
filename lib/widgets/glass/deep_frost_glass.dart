import 'package:flutter/widgets.dart';

import '../../theme/glass_tokens.dart';
import 'liquid_glass.dart';

class DeepFrostGlass extends StatelessWidget {
  const DeepFrostGlass({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.minHeight,
    this.blur = true,
    this.shadow = true,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final double? minHeight;
  final bool blur;
  final bool shadow;

  @override
  Widget build(BuildContext context) => LiquidGlass(
        material: GlassMaterial.frosted,
        borderRadius: borderRadius,
        padding: padding,
        width: width,
        height: height,
        minHeight: minHeight,
        blur: blur,
        shadow: shadow,
        child: child,
      );
}
