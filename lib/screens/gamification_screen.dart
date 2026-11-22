import 'package:flutter/material.dart';

import '../theme/bio_theme.dart';
import '../widgets/level_badge.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/community_widgets.dart';
import 'map_screen.dart';
import 'xp_history_screen.dart';

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

  static const _periodIcons = {
    'Diarias': Icons.today_rounded,
    'Semanales': Icons.date_range_rounded,
    'De evento': Icons.celebration_rounded,
    'Logros': Icons.emoji_events_rounded,
  };

  String _remaining(DateTime end) {
    final left = end.difference(DateTime.now());
    if (left.isNegative) return 'Terminó';
    if (left.inDays >= 1) return 'Quedan ${left.inDays} d';
    if (left.inHours >= 1) return 'Quedan ${left.inHours} h';
    return 'Quedan ${left.inMinutes.clamp(1, 59)} min';
  }

  Widget _mission(Mission mission) {
    final done = mission.completed;
    final value = done
        ? 1.0
        : mission.target > 0
        ? (mission.progress / mission.target).clamp(0.0, 1.0)
        : 0.0;
    return BioGlassCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: done
                        ? BioTheme.lime
                        : BioTheme.lime.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    done
                        ? Icons.check_rounded
                        : _periodIcons[mission.period] ?? Icons.flag_rounded,
                    color: done ? BioTheme.iconDark : BioTheme.lime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                      ),
                      if (mission.description.isNotEmpty)
                        Text(
                          mission.description,
                          style: const TextStyle(
                            color: BioTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: BioTheme.lime.withValues(alpha: .12),
                  ),
                  child: Text(
                    '+${mission.xp} XP',
                    style: const TextStyle(
                      color: BioTheme.lime,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: .1),
                color: BioTheme.lime,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${mission.target > 0 ? '${mission.progress.clamp(0, mission.target)}/${mission.target}' : 'Progreso: ${mission.progress}'} · ${mission.xp} XP${done ? ' · Completada' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BioTheme.textSecondary,
                    ),
                  ),
                ),
                if (mission.endsAt != null && !done)
                  Text(
                    _remaining(mission.endsAt!),
                    style: const TextStyle(
                      fontSize: 12,
                      color: BioTheme.textMuted,
                    ),
                  ),
              ],
            ),
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
  }

  Widget _section(String title, {String? subtitle}) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(color: BioTheme.textMuted, fontSize: 12.5),
          ),
      ],
    ),
  );

  Widget _curiosity(Curiosity curiosity) => BioGlassCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: BioTheme.lime, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'DATO CURIOSO DEL DÍA',
                  style: TextStyle(
                    color: BioTheme.lime,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(curiosity.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(curiosity.description, style: const TextStyle(height: 1.45)),
          if (curiosity.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: curiosity.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: curiosity.images.length == 1
                        ? MediaQuery.sizeOf(context).width - 72
                        : 250,
                    child: RemotePhoto(curiosity.images[i], height: 190),
                  ),
                ),
              ),
            ),
          ],
          if (curiosity.zone != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => _zone(curiosity.zone!),
                icon: const Icon(Icons.map_outlined),
                label: Text('Descubrir en el mapa · ${curiosity.zone!.name}'),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final curiosity = data?.curiosity;
    // Pendientes primero; las completadas quedan al final de cada grupo.
    List<Mission> sorted(Iterable<Mission> items) => [
      ...items.where((m) => !m.completed),
      ...items.where((m) => m.completed),
    ];
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
              description: 'Tus descubrimientos y visitas al campus se convierten en experiencia.',
            ),
            if (data != null)
              BioGlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          LevelBadge(level: data.level, size: 58),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nivel ${data.level} · ${badgeName(data.level)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                                Text(
                                  '${data.xp} puntos de experiencia',
                                  style: const TextStyle(
                                    color: BioTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (data.levelProgress != null) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: data.levelProgress,
                            minHeight: 9,
                            backgroundColor: Colors.white.withValues(alpha: .1),
                            color: BioTheme.lime,
                          ),
                        ),
                        if (data.nextLevelXp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Siguiente nivel a los ${data.nextLevelXp} XP',
                              style: const TextStyle(
                                fontSize: 12,
                                color: BioTheme.textMuted,
                              ),
                            ),
                          ),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('Ver historial de experiencia'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const XpHistoryScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (curiosity != null) _curiosity(curiosity),
            if (data != null) ...[
              if (!data.missionsAvailable)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Las misiones no están disponibles en este momento.',
                  ),
                ),
              if (data.missionsAvailable)
                for (final (period, title, subtitle) in const [
                  ('Diarias', 'Misiones diarias', 'Se renuevan cada día'),
                  (
                    'Semanales',
                    'Misiones semanales',
                    'Se renuevan cada semana',
                  ),
                  (
                    'De evento',
                    'Misiones de evento',
                    'Solo por tiempo limitado',
                  ),
                ]) ...[
                  _section(title, subtitle: subtitle),
                  for (final mission in sorted(
                    data.missions.where((m) => m.period == period),
                  ))
                    _mission(mission),
                  if (!data.missions.any((m) => m.period == period))
                    const Text(
                      'No hay misiones en este periodo.',
                      style: TextStyle(color: BioTheme.textMuted),
                    ),
                ],
              _section('Logros por completar'),
              for (final achievement in data.achievements.where(
                (a) => !a.completed,
              ))
                _mission(achievement),
              if (!data.achievements.any((a) => !a.completed))
                const Text(
                  '¡Completaste todos los logros disponibles!',
                  style: TextStyle(color: BioTheme.textMuted),
                ),
              _section('Logros obtenidos'),
              for (final achievement in data.achievements.where(
                (a) => a.completed,
              ))
                _mission(achievement),
              if (!data.achievements.any((a) => a.completed))
                const Text(
                  'Aún no tienes logros. ¡Registra tu primera observación!',
                  style: TextStyle(color: BioTheme.textMuted),
                ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
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
