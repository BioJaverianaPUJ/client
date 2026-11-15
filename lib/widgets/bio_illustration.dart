import 'package:flutter/material.dart';

class BioIllustration extends StatelessWidget {
  const BioIllustration({
    super.key,
    required this.asset,
    required this.color,
    required this.opacity,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.flipHorizontally = false,
  });

  final String asset;
  final Color color;
  final double opacity;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final bool flipHorizontally;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: BlendMode.srcIn,
      opacity: AlwaysStoppedAnimation(opacity),
    );

    if (flipHorizontally) {
      image = Transform.flip(flipX: true, child: image);
    }

    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: IgnorePointer(child: image),
    );
  }
}
