import 'package:flutter/material.dart';
import '../theme/bio_theme.dart';

class BioFooter extends StatelessWidget {
  const BioFooter({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 18 : 25),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/Yggdrasil.png',
          width: 18,
          height: 18,
          color: BioTheme.lime,
          colorBlendMode: BlendMode.srcIn,
        ),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'BIOJAVERIANA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BioTheme.textSecondary,
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
