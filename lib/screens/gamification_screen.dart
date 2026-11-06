import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'map_screen.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});
  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  ProgressSummary? _data;
  Object? _error;
  bool _busy = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await AppScope.read(context).community.progress();
      if (mounted) setState(() => _data = data);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _zone(CampusZone zone) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => MapScreen(focusZone: zone)),
  );
  Widget _mission(Mission mission) => BioGlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mission.title, style: Theme.of(context).textTheme.titleLarge),
          Text(mission.description),
          const SizedBox(height: 12),
          Text(
            '${mission.progress}/${mission.target} · ${mission.xp} XP${mission.completed ? ' · Completada' : ''}',
          ),
          LinearProgressIndicator(
            value: mission.target <= 0
                ? 0
                : (mission.progress / mission.target).clamp(0.0, 1.0),
          ),
          if (mission.endsAt != null)
            Text('Disponible hasta ${dateLabel(mission.endsAt!.toLocal())}'),
          if (mission.zone != null)
            TextButton.icon(
              onPressed: () => _zone(mission.zone!),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver zona en el mapa'),
            ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final data = _data;
    final curiosity = data?.curiosity;
    return CommunityScaffold(
      title: 'Gamificación',
      tab: BioTab.gamification,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const BioPageHeading(
              eyebrow: 'Cada descubrimiento cuenta',
              title: 'Explora. Aprende.',
              accent: 'Avanza.',
              description:
                  'Tus descubrimientos y visitas al campus se convierten en experiencia.',
            ),
            if (curiosity != null)
              BioGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATO CURIOSO DEL DÍA'),
                      const SizedBox(height: 12),
                      Text(
                        curiosity.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(curiosity.description),
                      for (final image in curiosity.images)
                        RemotePhoto(image, height: 180),
                      if (curiosity.zone != null)
                        TextButton(
                          onPressed: () => _zone(curiosity.zone!),
                          child: const Text('Descubrir en el mapa'),
                        ),
                    ],
                  ),
                ),
              ),
            if (data != null) ...[
              ListTile(
                leading: const Icon(Icons.workspace_premium, size: 40),
                title: Text('Nivel ${data.level}'),
                subtitle: Text('${data.xp} puntos de experiencia'),
              ),
              for (final period in ['Diarias', 'Semanales', 'De evento']) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Misiones $period',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final mission in data.missions.where(
                  (m) => m.period == period && !m.completed,
                ))
                  _mission(mission),
                if (!data.missions.any(
                  (m) => m.period == period && !m.completed,
                ))
                  const Text('No tienes misiones pendientes en este periodo.'),
              ],
              const SizedBox(height: 20),
              Text(
                'Logros por completar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final achievement in data.achievements.where(
                (a) => !a.completed,
              ))
                _mission(achievement),
              const SizedBox(height: 20),
              Text(
                'Logros obtenidos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final achievement in data.achievements.where(
                (a) => a.completed,
              ))
                _mission(achievement),
            ],
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              StatusPanel(
                title: 'Tus próximos retos están por llegar',
                message: messageFor(_error!),
                icon: Icons.emoji_events_outlined,
                action: _load,
              ),
          ],
        ),
      ),
    );
  }
}
