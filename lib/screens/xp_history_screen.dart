import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';

class XpHistoryScreen extends StatefulWidget {
  const XpHistoryScreen({super.key});
  @override
  State<XpHistoryScreen> createState() => _XpHistoryScreenState();
}

class _XpHistoryScreenState extends State<XpHistoryScreen> {
  final _items = <XpHistoryEntry>[];
  bool _busy = false, _hasMore = true;
  int _page = 0;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Historial de experiencia',
    body: RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Consulta la experiencia que has recibido y cómo ha cambiado tu nivel.',
          ),
          const SizedBox(height: 16),
          for (final item in _items)
            BioGlassCard(
              child: ListTile(
                leading: const Icon(Icons.stars_outlined),
                title: Text(
                  '${item.amount >= 0 ? '+' : ''}${item.amount} XP · ${item.reason}',
                ),
                subtitle: Text(
                  '${dateLabel(item.date.toLocal())} · Nivel ${item.levelAfter} · Total ${item.totalAfter} XP',
                ),
              ),
            ),
          if (!_busy && _error == null && _items.isEmpty)
            const Text('Todavía no tienes movimientos de experiencia.'),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            StatusPanel(
              title: 'No pudimos cargar el historial',
              message: messageFor(_error!),
              action: _load,
            ),
          if (!_busy && _error == null && _hasMore)
            TextButton(onPressed: _load, child: const Text('Cargar más')),
        ],
      ),
    ),
  );
}
