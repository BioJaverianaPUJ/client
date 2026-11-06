import 'package:flutter/material.dart';
import '../models/community.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';
import 'sighting_detail_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});
  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Sighting> _items = [];
  Verification? _filter;
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
      final items = await AppScope.read(context).community.sightings();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CommunityScaffold(
    title: 'Mis observaciones',
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BioPageHeading(
            eyebrow: 'Mis observaciones',
            title: 'Tu biodiversidad,',
            accent: 'registrada.',
            description:
                'Guarda tus encuentros con la naturaleza y construye tu propio registro del campus.',
          ),
          const Text(
            'Tus observaciones se guardan automáticamente, incluidas las fallidas. Tú decides cuáles compartir.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todas'),
                selected: _filter == null,
                onSelected: (_) => setState(() => _filter = null),
              ),
              for (final status in Verification.values)
                ChoiceChip(
                  label: Text(status.label),
                  selected: _filter == status,
                  onSelected: (_) => setState(() => _filter = status),
                ),
            ],
          ),
          for (final item in _items.where(
            (s) => _filter == null || s.status == _filter,
          ))
            BioGlassCard(
              child: ListTile(
                title: Text(item.species),
                subtitle: Text(
                  '${item.status.label} · ${dateLabel(item.date)}\n${item.published ? 'Publicada' : 'Personal'} · ${item.point.latitude.toStringAsFixed(5)}, ${item.point.longitude.toStringAsFixed(5)}',
                ),
                leading: SizedBox(
                  width: 56,
                  child: RemotePhoto(item.photo, height: 56),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SightingDetailScreen(sighting: item),
                    ),
                  );
                  if (mounted) await _load();
                },
              ),
            ),
          if (_busy) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            StatusPanel(
              title: 'Observaciones no disponibles',
              message: messageFor(_error!),
              action: _load,
            ),
          if (!_busy &&
              _error == null &&
              _items
                  .where((s) => _filter == null || s.status == _filter)
                  .isEmpty)
            const StatusPanel(
              title: 'Sin observaciones',
              message:
                  'Aquí aparecerán tus capturas cuando registres observaciones.',
            ),
        ],
      ),
    ),
  );
}
