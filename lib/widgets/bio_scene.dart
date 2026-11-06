import 'package:flutter/material.dart';
import '../theme/bio_theme.dart';
import '../theme/glass_tokens.dart';
import 'bio_illustration.dart';
import 'glass/glass_icon.dart';
import 'glass/liquid_glass.dart';

/// Decorative layers stay behind content and never intercept gestures.
class BioScene extends StatelessWidget {
  const BioScene({
    super.key,
    required this.child,
    this.illustration = 'lush_tree',
  });
  final Widget child;
  final String illustration;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(1, -.3),
              radius: 1.4,
              colors: [Color(0xFF124D40), BioTheme.backgroundDeep],
            ),
          ),
        ),
      ),
      BioIllustration(
        asset: 'assets/illustrations/$illustration.png',
        color: BioTheme.botanical,
        opacity: .19,
        right: -65,
        top: 60,
        width: 420,
        height: 740,
        fit: BoxFit.contain,
      ),
      const BioIllustration(
        asset: 'assets/illustrations/treeline_reflection.png',
        color: BioTheme.forest,
        opacity: .13,
        left: -50,
        right: -50,
        bottom: -50,
        height: 250,
        fit: BoxFit.cover,
      ),
      child,
    ],
  );
}

class BioGlassCard extends StatelessWidget {
  const BioGlassCard({
    super.key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.padding = EdgeInsets.zero,
    this.frosted = false,
  });
  final Widget child;
  final EdgeInsetsGeometry margin, padding;
  final bool frosted;
  @override
  Widget build(BuildContext context) => Padding(
    padding: margin,
    child: LiquidGlass(
      material: frosted ? GlassMaterial.frosted : GlassMaterial.clear,
      borderRadius: 30,
      padding: padding,
      child: Material(type: MaterialType.transparency, child: child),
    ),
  );
}

class BioPageHeading extends StatelessWidget {
  const BioPageHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.description,
  });
  final String eyebrow, title, accent, description;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: BioTheme.lime,
            fontSize: 10,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.displaySmall),
        Text(
          accent,
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: BioTheme.lime),
        ),
        const SizedBox(height: 16),
        Text(
          description,
          style: const TextStyle(
            color: BioTheme.textSecondary,
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class BioGlassAction extends StatelessWidget {
  const BioGlassAction({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BioGlassCard(
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GlassIcon(icon: icon, size: 48, iconSize: 25),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(color: BioTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: BioTheme.lime),
          ],
        ),
      ),
    ),
  );
}
