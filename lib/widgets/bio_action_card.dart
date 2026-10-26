import 'package:flutter/material.dart';

import '../theme/bio_text_styles.dart';
import '../theme/glass_tokens.dart';
import 'bio_pressable.dart';
import 'glass/liquid_glass.dart';

class BioActionCard extends StatelessWidget {
  const BioActionCard({
    super.key,
    required this.leading,
    required this.title,
    this.eyebrow,
    this.description,
    this.trailing,
    this.onTap,
    this.material = GlassMaterial.regular,
    this.borderRadius = 30,
    this.minHeight = 118,
    this.padding = const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
    this.titleStyle = BioTextStyles.cardTitle,
    this.descriptionStyle = BioTextStyles.cardDescription,
    this.descriptionWidthFactor = 1,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget leading;
  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;
  final GlassMaterial material;
  final double borderRadius;
  final double minHeight;
  final EdgeInsetsGeometry padding;
  final TextStyle titleStyle;
  final TextStyle descriptionStyle;
  final double descriptionWidthFactor;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final card = LiquidGlass(
      material: material,
      borderRadius: borderRadius,
      minHeight: minHeight,
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: minHeight - padding.vertical,
        ),
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            leading,
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow != null) ...[
                    Text(eyebrow!, style: BioTextStyles.cardEyebrow),
                    const SizedBox(height: 5),
                  ],
                  Text(title, style: titleStyle),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      widthFactor: descriptionWidthFactor,
                      child: Text(description!, style: descriptionStyle),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      ),
    );

    return onTap == null ? card : BioPressable(onTap: onTap, child: card);
  }
}
