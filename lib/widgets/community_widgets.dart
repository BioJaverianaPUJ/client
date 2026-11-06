import 'package:flutter/material.dart';
import '../services/api_exception.dart';
import '../services/community_repository.dart';
import '../theme/bio_theme.dart';
import 'bio_bottom_navigation.dart';
import 'bio_scene.dart';
import 'glass/glass_icon.dart';
export 'bio_scene.dart';

String messageFor(Object error) => switch (error) {
  ApiException e => e.message,
  FeatureUnavailable e => e.message,
  _ => 'No pudimos completar la acción. Intenta de nuevo.',
};

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    ) ??
    false;

class CommunityScaffold extends StatelessWidget {
  const CommunityScaffold({
    super.key,
    required this.title,
    required this.body,
    this.tab,
    this.actions,
    this.floatingActionButton,
  });
  final String title;
  final Widget body;
  final BioTab? tab;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  String get illustration => switch (tab) {
    BioTab.home => 'radiant_column',
    BioTab.map => 'flock_birds',
    BioTab.identify => 'floral_frame',
    BioTab.profile => 'layered_birds',
    BioTab.gamification => 'engraved_birds_branches',
    _ => title.contains('observacion') ? 'bare_tree' : 'lush_tree',
  };
  @override
  Widget build(BuildContext context) => BioScene(
    illustration: illustration,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 76,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: tab == null
            ? Text(title)
            : Image.asset(
                'assets/BioJaveriana.png',
                height: 70,
                fit: BoxFit.contain,
                color: BioTheme.lime,
                colorBlendMode: BlendMode.srcIn,
              ),
        actions: actions,
      ),
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: tab == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: BioBottomNavigation(activeTab: tab),
              ),
            ),
    ),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
    this.actionLabel = 'Reintentar',
  });
  final String title, message, actionLabel;
  final IconData icon;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => BioGlassCard(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.all(24),
    frosted: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassIcon(icon: icon, size: 62, iconSize: 30),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(onPressed: action, child: Text(actionLabel)),
          ),
      ],
    ),
  );
}

class RemotePhoto extends StatelessWidget {
  const RemotePhoto(this.url, {super.key, this.height = 280});
  final String url;
  final double height;
  @override
  Widget build(BuildContext context) => Image.network(
    url,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => SizedBox(
      height: height,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          semanticLabel: 'Imagen no disponible',
        ),
      ),
    ),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : SizedBox(
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          ),
  );
}

String dateLabel(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
