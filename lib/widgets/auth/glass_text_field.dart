import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/bio_icons.dart';
import '../../theme/bio_theme.dart';
import '../glass/deep_frost_glass.dart';
import '../glass/glass_icon.dart';

class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.onToggleObscure,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofillHints,
    this.maxLength,
    this.height = 58,
    this.iconSize = 41,
    this.glyphSize = 18,
    this.fontSize = 13.5,
    this.bottomSpacing = 18,
    this.labelSpacing = 8,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final double height;
  final double iconSize;
  final double glyphSize;
  final double fontSize;
  final double bottomSpacing;
  final double labelSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2, bottom: labelSpacing),
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFEBF1ED),
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          DeepFrostGlass(
            borderRadius: 25,
            height:
                height +
                (MediaQuery.textScalerOf(context).scale(fontSize) - fontSize),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Row(
              children: [
                GlassIcon(
                  icon: icon,
                  size: iconSize,
                  iconSize: glyphSize,
                  iconColor: BioTheme.iconDark,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    textInputAction: textInputAction,
                    autofillHints: autofillHints,
                    inputFormatters: maxLength == null
                        ? null
                        : [LengthLimitingTextInputFormatter(maxLength)],
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textCapitalization: textCapitalization,
                    autocorrect: false,
                    enableSuggestions: false,
                    cursorColor: BioTheme.lime,
                    style: TextStyle(
                      color: BioTheme.textPrimary,
                      fontSize: fontSize,
                    ),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: BioTheme.textMuted,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
                if (onToggleObscure != null)
                  IconButton(
                    tooltip: obscureText
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? BioIcons.eyeOutline
                          : BioIcons.eyeOffOutline,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
