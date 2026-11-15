import 'package:flutter/material.dart';

import '../theme/bio_text_styles.dart';
import 'bio_pressable.dart';
import 'glass/glass_icon.dart';
import 'glass/soft_frost_glass.dart';

class BioStatCard extends StatelessWidget {
  const BioStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.height = 130,
    this.valueStyle = BioTextStyles.statValue,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final double height;
  final TextStyle valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = SoftFrostGlass(
      borderRadius: 27,
      height: height,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassIcon(icon: icon, size: 39, iconSize: 17),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: valueStyle),
              const SizedBox(height: 1),
              Text(label, style: BioTextStyles.statLabel),
            ],
          ),
        ],
      ),
    );

    return onTap == null ? card : BioPressable(onTap: onTap, child: card);
  }
}

class BioStatRow extends StatelessWidget {
  const BioStatRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) const SizedBox(width: 9),
          Expanded(child: children[index]),
        ],
      ],
    );
  }
}
