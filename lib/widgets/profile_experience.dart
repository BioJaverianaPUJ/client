import 'package:flutter/material.dart';
import '../models/community.dart';
import '../models/experience.dart';
import '../state/app_scope.dart';
import 'community_widgets.dart';

class ProfileExperience extends StatefulWidget {
  const ProfileExperience({super.key, required this.userId});
  final String userId;
  @override
  State<ProfileExperience> createState() => _ProfileExperienceState();
}

class _ProfileExperienceState extends State<ProfileExperience> {
  ProgressSummary? _progress;
  bool _loading = true;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final progress = await AppScope.read(
        context,
      ).community.progress(userId: widget.userId);
      if (mounted) setState(() => _progress = progress);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final experience = _progress == null ? null : Experience(_progress!.xp);
    return BioGlassCard(
      frosted: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TU EXPERIENCIA', style: TextStyle(letterSpacing: 2)),
          const SizedBox(height: 12),
          if (_loading)
            const LinearProgressIndicator()
          else if (_error != null) ...[
            const Text('Experiencia pendiente de sincronización'),
            const Text(
              'Los puntos y el nivel aparecerán cuando el servicio de experiencia esté disponible.',
            ),
            TextButton(
              onPressed: _load,
              child: const Text('Actualizar experiencia'),
            ),
          ] else if (experience != null) ...[
            Row(
              children: [
                const Icon(Icons.workspace_premium_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nivel ${experience.level} · ${experience.xp} XP',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: experience.fraction,
              semanticsLabel: 'Progreso al siguiente nivel',
            ),
            const SizedBox(height: 8),
            Text(
              '${experience.nextThreshold - experience.xp} XP para el siguiente nivel',
            ),
            for (final achievement in _progress!.achievements.where(
              (a) => a.completed,
            ))
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: Text(achievement.title),
              ),
          ],
        ],
      ),
    );
  }
}
