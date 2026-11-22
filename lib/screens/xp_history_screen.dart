import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';
import '../widgets/level_badge.dart';

class XpHistoryScreen extends StatefulWidget {
  const XpHistoryScreen({super.key});
  @override
  State<XpHistoryScreen> createState() => _XpHistoryScreenState();
}

const _months = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// Tipo, ícono y nombre legible de cada movimiento de experiencia. El
/// backend guarda el origen como "ACHIEVEMENT:slug" o "MISSION:slug".
(String, IconData, String) describeXp(
  String reason,
  Map<String, String> names,
) {
  String pretty(String slug) {
    final text = slug.replaceAll(RegExp(r'[-_]+'), ' ').trim();
    return text.isEmpty ? slug : text[0].toUpperCase() + text.substring(1);
  }

  final i = reason.indexOf(':');
  final kind = i > 0 ? reason.substring(0, i) : '';
  final slug = i > 0 ? reason.substring(i + 1) : reason;
  final name = names[reason] ?? pretty(slug);
  return switch (kind) {
    'ACHIEVEMENT' => ('Logro', Icons.emoji_events_rounded, name),
    'MISSION' => ('Misión', Icons.flag_rounded, name),
    _ => ('Experiencia', Icons.auto_awesome_rounded, name),
  };
}

class _XpHistoryScreenState extends State<XpHistoryScreen> {
  final _items = <XpHistoryEntry>[];
  bool _busy = false, _hasMore = true;
  int _page = 0;
  Object? _error;
  ProgressSummary? _progress;
  Map<String, String> _names = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadSummary();
    });
  }

  Future<void> _loadSummary() async {
    final community = AppScope.read(context).community;
    try {
      final results = await Future.wait([
        community.progress(),
        community.rewardNames(),
      ]);
      if (!mounted) return;
      setState(() {
        _progress = results[0] as ProgressSummary;
        _names = results[1] as Map<String, String>;
      });
    } catch (_) {
      // El historial se muestra aunque falte el resumen.
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final next = refresh ? 0 : _page;
      final data = await AppScope.read(context).community.xpHistory(page: next);
      if (!mounted) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(data.items);
        _page = next + 1;
        _hasMore = data.hasMore;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _day(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    final year = date.year == now.year ? '' : ' de ${date.year}';
    return '${date.day} de ${_months[date.month - 1]}$year';
  }

  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour < 12 ? 'a. m.' : 'p. m.'}';
  }

  Widget _summary() {
    final progress = _progress;
    final latest = _items.isEmpty ? null : _items.first;
    final level = progress?.level ?? latest?.levelAfter;
    final xp = progress?.xp ?? latest?.totalAfter;
    if (level == null || xp == null) return const SizedBox.shrink();
    final week = DateTime.now().subtract(const Duration(days: 7));
    final thisWeek = _items
        .where((e) => e.date.toLocal().isAfter(week))
        .fold<int>(0, (sum, e) => sum + e.amount);
    final rewards = _items.length;
    return BioGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LevelBadge(level: level, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nivel $level · ${badgeName(level)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$xp XP en total',
                        style: const TextStyle(color: BioTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress?.levelProgress != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress!.levelProgress,
                  minHeight: 9,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  color: BioTheme.lime,
                ),
              ),
              if (progress.nextLevelXp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Faltan ${(progress.nextLevelXp! - xp).clamp(0, 1 << 31)} XP para el nivel ${level + 1}',
                    style: const TextStyle(
                      color: BioTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                _Stat(
                  value: '${thisWeek >= 0 ? '+' : ''}$thisWeek',
                  label: 'XP esta semana',
                ),
                const SizedBox(width: 10),
                _Stat(
                  value: '$rewards${_hasMore ? '+' : ''}',
                  label: 'Recompensas',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _timeline() {
    final widgets = <Widget>[];
    String? currentDay;
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      final date = item.date.toLocal();
      final day = _day(date);
      if (day != currentDay) {
        currentDay = day;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
            child: Text(
              day.toUpperCase(),
              style: const TextStyle(
                color: BioTheme.lime,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
        );
      }
      // La lista viene de la más reciente a la más antigua.
      final older = i + 1 < _items.length ? _items[i + 1] : null;
      final levelUp = older != null && item.levelAfter > older.levelAfter;
      if (levelUp) widgets.add(_LevelUp(level: item.levelAfter));
      widgets.add(_entry(item, date));
    }
    return widgets;
  }

  Widget _entry(XpHistoryEntry item, DateTime date) {
    final (kind, icon, name) = describeXp(item.reason, _names);
    final positive = item.amount >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BioTheme.lime.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: BioTheme.lime, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: BioTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$kind · ${_time(date)} · total ${item.totalAfter}',
                  style: const TextStyle(
                    color: BioTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: positive
                  ? BioTheme.lime.withValues(alpha: 0.16)
                  : BioTheme.danger.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${positive ? '+' : ''}${item.amount} XP',
              style: TextStyle(
                color: positive ? BioTheme.lime : BioTheme.danger,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Historial de experiencia',
    body: RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_load(refresh: true), _loadSummary()]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _summary(),
          ..._timeline(),
          if (!_busy && _error == null && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    color: BioTheme.lime,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Todavía no tienes experiencia',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Completa misiones y logros para empezar a subir de nivel.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: BioTheme.textMuted),
                  ),
                ],
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            StatusPanel(
              title: 'No pudimos cargar el historial',
              message: messageFor(_error!),
              action: _load,
            ),
          if (!_busy && _error == null && _hasMore && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Ver movimientos anteriores'),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: BioTheme.lime,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: BioTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _LevelUp extends StatelessWidget {
  const _LevelUp({required this.level});
  final int level;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          BioTheme.lime.withValues(alpha: 0.28),
          BioTheme.lime.withValues(alpha: 0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        LevelBadge(level: level, size: 30),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '¡Subiste a nivel $level · ${badgeName(level)}!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
