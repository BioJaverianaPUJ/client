import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/bio_theme.dart';
import '../bio_footer.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.children,
    this.decorations = const [],
    this.minContentHeight = 0,
  });

  final List<Widget> children;
  final List<Widget> decorations;
  final double minContentHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioTheme.backgroundDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(constraints.maxHeight, minContentHeight),
                ),
                child: Stack(
                  fit: StackFit.passthrough,
                  clipBehavior: Clip.hardEdge,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: BioTheme.backgroundDeep),
                    ),
                    ...decorations,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(23, 37, 23, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthBrandHeader(),
                          ...children,
                          const SizedBox(height: 24),
                          const BioFooter(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/BioJaveriana.png',
          height: 108,
          width: double.infinity,
          fit: BoxFit.contain,
          color: BioTheme.lime,
          colorBlendMode: BlendMode.srcIn,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'EXPLORA · DESCUBRE · PROTEGE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFAEBFB7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.titleSize = 39,
    this.titleHeight = 43,
    this.titleLetterSpacing = -1.55,
    this.subtitleSize = 13.5,
    this.subtitleHeight = 19,
    this.subtitleTop = 8,
    this.subtitleMaxWidth = 290,
    this.dividerSpacing = 21,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final double titleSize;
  final double titleHeight;
  final double titleLetterSpacing;
  final double subtitleSize;
  final double subtitleHeight;
  final double subtitleTop;
  final double subtitleMaxWidth;
  final double dividerSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: BioTheme.limeSoft,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: BioTheme.textPrimary,
            fontSize: titleSize,
            height: titleHeight / titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: titleLetterSpacing,
          ),
        ),
        SizedBox(height: subtitleTop),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: subtitleMaxWidth),
          child: Text(
            subtitle,
            style: TextStyle(
              color: BioTheme.textSecondary,
              fontSize: subtitleSize,
              height: subtitleHeight / subtitleSize,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: dividerSpacing),
          child: const SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: Color.fromRGBO(213, 232, 206, 0.075)),
          ),
        ),
      ],
    );
  }
}

class AuthLink extends StatelessWidget {
  const AuthLink({
    super.key,
    required this.question,
    required this.action,
    required this.onTap,
    this.leading,
    this.top = 20,
  });

  final String question;
  final String action;
  final VoidCallback onTap;
  final Widget? leading;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 5)],
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: '$question ',
                      children: [
                        TextSpan(
                          text: action,
                          style: const TextStyle(
                            color: BioTheme.lime,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFB3C2BA),
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
