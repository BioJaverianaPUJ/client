import 'package:flutter/material.dart';

import '../theme/bio_text_styles.dart';
import '../theme/bio_theme.dart';
import 'bio_bottom_navigation.dart';
import 'bio_footer.dart';
import 'bio_top_bar.dart';

class BioScreen extends StatelessWidget {
  const BioScreen({
    super.key,
    required this.children,
    this.decorations = const [],
    this.activeTab,
    this.showProfileButton = true,
  });

  final List<Widget> children;
  final List<Widget> decorations;
  final BioTab? activeTab;
  final bool showProfileButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BioTheme.backgroundDeep,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: BioTheme.backgroundDeep),
            ),
            ...decorations,
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 155),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BioTopBar(showProfileButton: showProfileButton),
                    ...children,
                    const SizedBox(height: 18),
                    const BioFooter(compact: true),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 15,
              child: BioBottomNavigation(activeTab: activeTab),
            ),
          ],
        ),
      ),
    );
  }
}

class BioIntro extends StatelessWidget {
  const BioIntro({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.accent,
    required this.description,
    this.descriptionWidthFactor = 0.89,
    this.top = 18,
  });

  final String eyebrow;
  final String title;
  final String accent;
  final String description;
  final double descriptionWidthFactor;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: BioTextStyles.eyebrow),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              text: '$title\n',
              children: [
                TextSpan(
                  text: accent,
                  style: const TextStyle(color: BioTheme.lime),
                ),
              ],
            ),
            style: BioTextStyles.screenTitle,
          ),
          const SizedBox(height: 13),
          FractionallySizedBox(
            widthFactor: descriptionWidthFactor,
            child: Text(description, style: BioTextStyles.screenDescription),
          ),
        ],
      ),
    );
  }
}
