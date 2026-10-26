import 'package:flutter/material.dart';

import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../glass/liquid_glass.dart';

class AuthMessage extends StatelessWidget {
  const AuthMessage({
    super.key,
    required this.text,
    this.isError = true,
  });

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        child: LiquidGlass(
          borderRadius: 18,
          blur: false,
          minHeight: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                isError
                    ? BioIcons.alertCircleOutline
                    : BioIcons.informationOutline,
                size: 18,
                color: isError ? BioTheme.danger : BioTheme.lime,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFFC8D4CD),
                    fontSize: 11.5,
                    height: 16 / 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
