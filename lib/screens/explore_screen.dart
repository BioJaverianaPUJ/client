import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../widgets/community_widgets.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  final List<Map<String, dynamic>> _items = [];
  int _page = 0;
  bool _more = true, _busy = false;
  Object? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = await AppScope.read(
        context,
      ).catalog.page('species', reset ? 0 : _page);
      if (mounted) {
        setState(() {
          if (reset) {
            _items.clear();
            _page = 0;
          }
          _items.addAll(page.items);
          _page++;
          _more = page.hasNext;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final items = _items.where(
      (s) => [
        'commonName',
        'scientificName',
        'family',
      ].any((key) => '${s[key] ?? ''}'.toLowerCase().contains(query)),
    );
    return CommunityScaffold(
      title: 'Catálogo de especies',
      body: RefreshIndicator(
        onRefresh: () => _load(reset: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const BioPageHeading(
              eyebrow: 'Explora el campus',
              title: 'Descubre la',
              accent: 'biodiversidad.',
              description:
                  'Busca especies y conoce la vida que comparte contigo el campus.',
            ),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Buscar entre las especies cargadas',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            for (final species in items)
              BioGlassCard(
                child: ListTile(
                  leading: const Icon(Icons.park_outlined),
                  title: Text(
                    '${species['commonName'] ?? species['scientificName']}',
                  ),
                  subtitle: Text(
                    '${species['scientificName']} · ${species['family']}',
                  ),
                  onTap: () => showSpecies(context, species),
                ),
              ),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              StatusPanel(
                title: 'No pudimos cargar las especies',
                message: messageFor(_error!),
                action: _load,
              ),
            if (!_busy && _error == null && items.isEmpty)
              const StatusPanel(
                title: 'Sin resultados',
                message:
                    'No hay especies que coincidan entre los registros cargados.',
              ),
            if (_more && !_busy)
              OutlinedButton(
                onPressed: _load,
                child: const Text('Cargar más especies'),
              ),
          ],
        ),
      ),
    );
  }
}

void showSpecies(
  BuildContext context,
  Map<String, dynamic> species, {
  Map<String, dynamic>? specimen,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${species['commonName'] ?? species['scientificName']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${species['scientificName'] ?? ''}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Text('Familia: ${species['family'] ?? 'Sin información'}'),
            Text(
              'Densidad de madera: ${species['woodDensity'] ?? 'Sin información'}',
            ),
            if (specimen != null) ...[
              const Divider(),
              const Text('Espécimen oficial'),
              Text('Altura: ${specimen['height'] ?? 'Sin información'} m'),
              Text(
                'Circunferencia: ${specimen['circumference'] ?? 'Sin información'} m',
              ),
              Text(
                'Estado: ${switch (specimen['healthStatus']) {
                  'WELL' => 'Bueno',
                  'FAIR' => 'Regular',
                  'POOR' => 'Malo',
                  'DEAD' => 'Muerto',
                  _ => 'Sin información',
                }}',
              ),
              Text(
                'Ubicación: ${specimen['latitude']}, ${specimen['longitude']}',
              ),
              if (specimen['notes'] != null) Text('${specimen['notes']}'),
            ],
            const SizedBox(height: 16),
            const Text('Las imágenes de referencia aún no están disponibles.'),
          ],
        ),
      ),
    ),
  );
}
