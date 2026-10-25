import 'package:flutter/material.dart';

import '../theme/bio_theme.dart';

class BioFooter extends StatelessWidget {
  const BioFooter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: SizedBox(
        height: 1,
        child: ColoredBox(color: Color.fromRGBO(207, 227, 197, 0.055)),
      ),
    );

    final logoSize = compact ? 16.0 : 18.0;

    return IgnorePointer(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 30,
          vertical: compact ? 18 : 25,
        ),
        child: Row(
          children: [
            line,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Image.asset(
                      'assets/Yggdrasil.png',
                      width: logoSize,
                      height: logoSize,
                      color: BioTheme.lime,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BIOJAVERIANA',
                    style: TextStyle(
                      color: const Color(0xFFB5C4BB),
                      fontSize: compact ? 8 : 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: compact ? 1.4 : 1.55,
                    ),
                  ),
                ],
              ),
            ),
            line,
          ],
        ),
      ),
    );
  }
}
