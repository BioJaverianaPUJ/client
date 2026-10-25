import 'package:flutter/material.dart';

import '../theme/bio_text_styles.dart';

class BioSectionHeader extends StatelessWidget {
  const BioSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.top = 31,
    this.bottom = 14,
  });

  final String title;
  final Widget? trailing;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Row(
        children: [
          Text(title, style: BioTextStyles.sectionEyebrow),
          const SizedBox(width: 12),
          const Expanded(
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: Color.fromRGBO(211, 229, 205, 0.075)),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}
