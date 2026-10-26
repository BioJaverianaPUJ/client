import 'package:flutter/material.dart';

import '../models/bio_category.dart';
import '../theme/bio_theme.dart';
import 'bio_pressable.dart';

class BioFilterChip extends StatelessWidget {
  const BioFilterChip({
    super.key,
    required this.category,
    required this.active,
    required this.onTap,
    this.tinted = false,
    this.iconSize = 16,
  });

  final BioCategory category;
  final bool active;
  final VoidCallback onTap;
  final bool tinted;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final background = active
        ? BioTheme.lime
        : tinted
            ? const Color.fromRGBO(29, 75, 67, 0.54)
            : const Color.fromRGBO(255, 255, 255, 0.035);

    final border = active
        ? BioTheme.lime
        : tinted
            ? const Color.fromRGBO(215, 235, 222, 0.14)
            : const Color.fromRGBO(225, 238, 228, 0.16);

    return BioPressable(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: EdgeInsets.symmetric(horizontal: tinted ? 14 : 15),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: iconSize,
              color: active ? BioTheme.backgroundDeep : BioTheme.limeSoft,
            ),
            const SizedBox(width: 7),
            Text(
              category.label,
              style: TextStyle(
                color: active ? BioTheme.backgroundDeep : BioTheme.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BioFilterBar extends StatelessWidget {
  const BioFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.tinted = false,
    this.iconSize = 16,
  });

  final BioCategory selected;
  final ValueChanged<BioCategory> onSelected;
  final bool tinted;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.only(right: 20),
      child: Row(
        children: [
          for (final category in BioCategory.values) ...[
            if (category != BioCategory.values.first) const SizedBox(width: 9),
            BioFilterChip(
              category: category,
              active: category == selected,
              tinted: tinted,
              iconSize: iconSize,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}
