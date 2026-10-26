import 'package:flutter/material.dart';

import '../theme/bio_theme.dart';

class BioDot extends StatelessWidget {
  const BioDot({super.key, this.size = 5});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: BioTheme.lime,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class BioBadge extends StatelessWidget {
  const BioBadge({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 11,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: compact
            ? const Color.fromRGBO(255, 255, 255, 0.025)
            : const Color.fromRGBO(187, 211, 171, 0.055),
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(
          color: compact
              ? const Color.fromRGBO(221, 238, 210, 0.10)
              : const Color.fromRGBO(221, 238, 210, 0.09),
          width: 0.7,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BioDot(),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: BioTheme.limeSoft,
              fontSize: compact ? 7 : 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: compact ? 1.2 : 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
