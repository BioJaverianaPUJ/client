import 'package:flutter/material.dart';
import '../theme/bio_theme.dart';
import '../theme/glass_tokens.dart';
import 'bio_illustration.dart';
import 'glass/glass_icon.dart';
import 'glass/liquid_glass.dart';

/// Decorative layers stay behind content and never intercept gestures.
///
/// Las ilustraciones grandes se anclan al borde derecho y quedan cortadas
/// casi por la mitad, para que se vean grandes sin competir con el contenido.
class BioScene extends StatelessWidget {
  const BioScene({
    super.key,
    required this.child,
    this.illustration = 'lush_tree',
    this.opacity,
  });
  final Widget child;

  /// Nombre del archivo en assets/illustrations (sin extensión) o null para
  /// un fondo limpio solo con degradado.
  final String? illustration;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final art = illustration;
    return Stack(
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
        if (art != null) _artwork(art, size),
        // Velo inferior: mantiene legible el contenido sobre la ilustración.
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .62, 1],
                  colors: [
                    Color(0x00002E29),
                    Color(0x00002E29),
                    Color(0x99002E29),
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _artwork(String art, Size size) {
    final w = size.width;
    final asset = 'assets/illustrations/$art.png';
    switch (art) {
      // Cámara: rama con pájaro completa, de borde a borde, sin recortes.
      case 'tree_branchs_bird':
        return BioIllustration(
          asset: asset,
          color: BioTheme.botanical,
          opacity: opacity ?? .2,
          left: 0,
          top: 70,
          width: w,
          height: w * 1024 / 1536,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        );
      // Perfil: los dos pájaros completos, como estaban antes.
      case 'layered_birds':
        return BioIllustration(
          asset: asset,
          color: BioTheme.botanical,
          opacity: opacity ?? .16,
          left: 0,
          top: 65,
          width: w * 1.65,
          height: size.height * 1.15,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        );
      // Acento pequeño para pantallas que deben verse limpias.
      case 'scattered_birds':
      case 'flock_birds':
        return BioIllustration(
          asset: asset,
          color: BioTheme.botanical,
          opacity: opacity ?? .14,
          right: -w * .12,
          top: 70,
          width: w * .85,
          height: w * .5,
          fit: BoxFit.contain,
          alignment: Alignment.topRight,
        );
      default:
        final artWidth = w * 1.3;
        return BioIllustration(
          asset: asset,
          color: BioTheme.botanical,
          opacity: opacity ?? .16,
          // El centro de la ilustración queda sobre el borde derecho.
          left: w - artWidth * .5,
          top: 56,
          width: artWidth,
          height: size.height * 1.1,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
        );
    }
  }
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
