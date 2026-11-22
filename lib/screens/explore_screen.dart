import '../widgets/species_symbol.dart';
import '../widgets/species_reference_photos.dart';
import 'package:flutter/material.dart';
import '../state/app_scope.dart';
import '../theme/bio_theme.dart';
import '../widgets/community_widgets.dart';

enum _Sort { common, scientific, family, specimens, density }

const _sortLabels = {
  _Sort.common: 'Nombre común (A-Z)',
  _Sort.scientific: 'Nombre científico (A-Z)',
  _Sort.family: 'Familia',
  _Sort.specimens: 'Más ejemplares en el campus',
  _Sort.density: 'Mayor densidad de madera',
};

const healthLabels = {
  'WELL': 'Bueno',
  'FAIR': 'Regular',
  'POOR': 'Malo',
  'DEAD': 'Muerto',
  'UNKNOWN': 'Sin dato',
};
const healthColors = {
  'WELL': Color(0xFF9CCB72),
  'FAIR': Color(0xFFE3C46B),
  'POOR': Color(0xFFF0A58F),
  'DEAD': Color(0xFF8A948F),
  'UNKNOWN': Color(0xFF5C7A70),
};

/// Quita tildes y pasa a minúsculas para buscar sin importar la escritura.
String _fold(Object? value) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
  const to = 'aaaaaeeeeiiiiooooouuuunc';
  final text = '${value ?? ''}'.toLowerCase();
  final out = StringBuffer();
  for (final ch in text.split('')) {
    final i = from.indexOf(ch);
    out.write(i >= 0 ? to[i] : ch);
  }
  return out.toString();
}

/// Catálogo de especies con búsqueda, grupos, familia, presencia y orden.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _species = [];
  final Map<String, int> _counts = {};
  final Map<String, Map<String, int>> _health = {};
  bool _loading = true, _countsLoaded = false, _onlyCampus = false;
  String? _group, _family;
  _Sort _sort = _Sort.common;
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

  Future<void> _load() async {
    final catalog = AppScope.read(context).catalog;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = <Map<String, dynamic>>[];
      for (var p = 0; ; p++) {
        final page = await catalog.page('species', p);
        all.addAll(page.items);
        if (!page.hasNext || p > 50) break;
      }
      if (!mounted) return;
      setState(() => _species = all);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    // Los ejemplares solo enriquecen la lista: si fallan, no bloquean.
    try {
      final counts = <String, int>{};
      final health = <String, Map<String, int>>{};
      for (var p = 0; ; p++) {
        final page = await catalog.page('specimens', p);
        for (final s in page.items) {
          final id = '${s['speciesId']}';
          final h = '${s['healthStatus'] ?? 'UNKNOWN'}';
          counts[id] = (counts[id] ?? 0) + 1;
          final byHealth = health.putIfAbsent(id, () => {});
          byHealth[h] = (byHealth[h] ?? 0) + 1;
        }
        if (!page.hasNext || p > 200) break;
      }
      if (!mounted) return;
      setState(() {
        _counts
          ..clear()
          ..addAll(counts);
        _health
          ..clear()
          ..addAll(health);
        _countsLoaded = true;
      });
    } catch (_) {}
  }

  int _count(Map<String, dynamic> s) => _counts['${s['id']}'] ?? 0;

  List<Map<String, dynamic>> get _filtered {
    final needle = _fold(_search.text.trim());
    final list = _species.where((s) {
      if (needle.isNotEmpty &&
          ![
            s['commonName'],
            s['scientificName'],
            s['family'],
          ].any((v) => _fold(v).contains(needle))) {
        return false;
      }
      if (_group != null && SpeciesGroups.of(s).label != _group) return false;
      if (_family != null && '${s['family'] ?? ''}' != _family) return false;
      if (_onlyCampus && _count(s) == 0) return false;
      return true;
    }).toList();
    int byName(Map<String, dynamic> a, Map<String, dynamic> b, String key) =>
        _fold(a[key]).compareTo(_fold(b[key]));
    list.sort(
      (a, b) => switch (_sort) {
        _Sort.common => byName(
          a,
          b,
          a['commonName'] != null ? 'commonName' : 'scientificName',
        ),
        _Sort.scientific => byName(a, b, 'scientificName'),
        _Sort.family => byName(a, b, 'family') != 0
            ? byName(a, b, 'family')
            : byName(a, b, 'commonName'),
        _Sort.specimens => _count(b) - _count(a) != 0
            ? _count(b) - _count(a)
            : byName(a, b, 'commonName'),
        _Sort.density => ((b['woodDensity'] as num?) ?? -1).compareTo(
          (a['woodDensity'] as num?) ?? -1,
        ),
      },
    );
    return list;
  }

  bool get _filtering =>
      _search.text.trim().isNotEmpty ||
      _group != null ||
      _family != null ||
      _onlyCampus;

  void _clear() => setState(() {
    _search.clear();
    _group = null;
    _family = null;
    _onlyCampus = false;
  });

  Future<void> _pickFamily() async {
    final counts = <String, int>{};
    for (final s in _species) {
      final f = '${s['family'] ?? ''}'.trim();
      if (f.isNotEmpty) counts[f] = (counts[f] ?? 0) + 1;
    }
    final families = counts.keys.toList()..sort();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: BioTheme.backgroundDeep,
      builder: (_) => _FamilySheet(
        families: families,
        counts: counts,
        selected: _family,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _family = picked.isEmpty ? null : picked);
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_Sort>(
      context: context,
      showDragHandle: true,
      backgroundColor: BioTheme.backgroundDeep,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ordenar por',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
            ),
            for (final entry in _sortLabels.entries)
              ListTile(
                leading: Icon(
                  entry.key == _sort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: entry.key == _sort
                      ? BioTheme.lime
                      : BioTheme.textMuted,
                ),
                title: Text(entry.value),
                enabled:
                    _countsLoaded || entry.key != _Sort.specimens,
                onTap: () => Navigator.pop(sheet, entry.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final groups = <String, (SpeciesGroup, int)>{};
    for (final s in _species) {
      final g = SpeciesGroups.of(s);
      groups[g.label] = (g, (groups[g.label]?.$2 ?? 0) + 1);
    }
    final groupList = groups.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final families = _species
        .map((s) => '${s['family'] ?? ''}')
        .where((f) => f.isNotEmpty)
        .toSet()
        .length;
    final totalSpecimens = _counts.values.fold<int>(0, (a, b) => a + b);
    final byLetter = _sort == _Sort.common || _sort == _Sort.scientific;
    final rows = <Widget>[];
    String? letter;
    for (final s in items) {
      if (byLetter) {
        final name = _fold(
          _sort == _Sort.scientific
              ? s['scientificName']
              : s['commonName'] ?? s['scientificName'],
        );
        final first = name.isEmpty ? '#' : name[0].toUpperCase();
        if (first != letter) {
          letter = first;
          rows.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 6, 6),
              child: Text(
                first,
                style: const TextStyle(
                  color: BioTheme.lime,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }
      }
      rows.add(
        _SpeciesTile(
          species: s,
          count: _countsLoaded ? _count(s) : null,
          onTap: () => showSpecies(
            context,
            s,
            specimenCount: _countsLoaded ? _count(s) : null,
            health: _health['${s['id']}'],
          ),
        ),
      );
    }
    return CommunityScaffold(
      title: 'Catálogo de especies',
      illustration: 'scattered_birds',
      illustrationOpacity: .1,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Row(
              children: [
                _Stat(value: '${_species.length}', label: 'especies'),
                _Stat(value: '$families', label: 'familias'),
                _Stat(
                  value: _countsLoaded ? '$totalSpecimens' : '…',
                  label: 'ejemplares',
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Busca por nombre común, científico o familia',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar búsqueda',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _GroupChip(
                    label: 'Todas',
                    count: _species.length,
                    selected: _group == null,
                    onTap: () => setState(() => _group = null),
                  ),
                  for (final (g, n) in groupList)
                    _GroupChip(
                      label: g.label,
                      count: n,
                      icon: g.icon,
                      color: g.color,
                      selected: _group == g.label,
                      onTap: () => setState(
                        () => _group = _group == g.label ? null : g.label,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterPill(
                  icon: Icons.account_tree_outlined,
                  label: _family ?? 'Familia',
                  active: _family != null,
                  onTap: _pickFamily,
                ),
                _FilterPill(
                  icon: Icons.sort_rounded,
                  label: _sortLabels[_sort]!,
                  active: _sort != _Sort.common,
                  onTap: _pickSort,
                ),
                _FilterPill(
                  icon: Icons.park_outlined,
                  label: 'Solo en el campus',
                  active: _onlyCampus,
                  onTap: _countsLoaded
                      ? () => setState(() => _onlyCampus = !_onlyCampus)
                      : null,
                ),
              ],
            ),
            if (_filtering)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${items.length} de ${_species.length} especies',
                        style: const TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Limpiar filtros'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            ...rows,
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              StatusPanel(
                title: 'No pudimos cargar las especies',
                message: messageFor(_error!),
                action: _load,
              ),
            if (!_loading && _error == null && items.isEmpty)
              StatusPanel(
                title: 'Sin resultados',
                message: _filtering
                    ? 'Ninguna especie coincide con estos filtros.'
                    : 'Todavía no hay especies en el catálogo.',
                icon: Icons.search_off_rounded,
                action: _filtering ? _clear : null,
                actionLabel: 'Limpiar filtros',
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: BioGlassCard(
      frosted: true,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: BioTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
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

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Material(
      color: selected
          ? BioTheme.lime
          : Colors.white.withValues(alpha: 0.05),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? BioTheme.lime
              : Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 17,
                  color: selected ? BioTheme.iconDark : color,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? BioTheme.iconDark : BioTheme.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? BioTheme.iconDark : BioTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: active
        ? BioTheme.lime.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.05),
    shape: StadiumBorder(
      side: BorderSide(
        color: active ? BioTheme.lime : Colors.white.withValues(alpha: 0.14),
      ),
    ),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? BioTheme.lime : BioTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? BioTheme.lime : BioTheme.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (onTap != null && label != 'Solo en el campus')
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: active ? BioTheme.lime : BioTheme.textMuted,
              ),
          ],
        ),
      ),
    ),
  );
}

class _FamilySheet extends StatefulWidget {
  const _FamilySheet({
    required this.families,
    required this.counts,
    required this.selected,
  });
  final List<String> families;
  final Map<String, int> counts;
  final String? selected;
  @override
  State<_FamilySheet> createState() => _FamilySheetState();
}

class _FamilySheetState extends State<_FamilySheet> {
  final _q = TextEditingController();
  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needle = _fold(_q.text.trim());
    final shown = widget.families
        .where((f) => _fold(f).contains(needle))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _q,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Buscar familia',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(
                      widget.selected == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: BioTheme.lime,
                    ),
                    title: const Text('Todas las familias'),
                    onTap: () => Navigator.pop(context, ''),
                  ),
                  for (final f in shown)
                    ListTile(
                      leading: Icon(
                        widget.selected == f
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: widget.selected == f
                            ? BioTheme.lime
                            : BioTheme.textMuted,
                      ),
                      title: Text(f),
                      trailing: Text(
                        '${widget.counts[f]}',
                        style: const TextStyle(color: BioTheme.textMuted),
                      ),
                      onTap: () => Navigator.pop(context, f),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeciesTile extends StatelessWidget {
  const _SpeciesTile({
    required this.species,
    required this.count,
    required this.onTap,
  });
  final Map<String, dynamic> species;
  final int? count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => BioGlassCard(
    margin: const EdgeInsets.only(bottom: 10),
    child: InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            SpeciesSymbol(species),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${species['commonName'] ?? species['scientificName']}',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${species['scientificName'] ?? ''}',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                      color: BioTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _GroupTag(species),
                ],
              ),
            ),
            if (count != null && count! > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: BioTheme.lime.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.park_rounded,
                      size: 14,
                      color: BioTheme.lime,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: BioTheme.lime,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Icon(Icons.chevron_right, color: BioTheme.lime),
          ],
        ),
      ),
    ),
  );
}

class _GroupTag extends StatelessWidget {
  const _GroupTag(this.species);
  final Map<String, dynamic> species;
  @override
  Widget build(BuildContext context) {
    final group = SpeciesGroups.of(species);
    final family = '${species['family'] ?? ''}'.trim();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _Tag(group.label, group.color),
        if (family.isNotEmpty) _Tag(family, BioTheme.textMuted),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

void showSpecies(
  BuildContext context,
  Map<String, dynamic> species, {
  Map<String, dynamic>? specimen,
  int? specimenCount,
  Map<String, int>? health,
}) {
  final group = SpeciesGroups.of(species);
  final density = species['woodDensity'];
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
            Row(
              children: [
                SpeciesSymbol(species, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(Icons.category_outlined, group.label, group.color),
                _InfoChip(
                  Icons.account_tree_outlined,
                  '${species['family'] ?? 'Familia sin dato'}',
                  BioTheme.textSecondary,
                ),
                _InfoChip(
                  Icons.scale_outlined,
                  density == null
                      ? 'Densidad sin dato'
                      : 'Densidad $density g/cm³',
                  BioTheme.textSecondary,
                ),
              ],
            ),
            if (specimenCount != null) ...[
              const SizedBox(height: 16),
              Text(
                specimenCount == 0
                    ? 'Aún no hay ejemplares oficiales registrados en el campus.'
                    : '$specimenCount ${specimenCount == 1 ? 'ejemplar' : 'ejemplares'} en el campus',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              if (health != null && health.isNotEmpty) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      children: [
                        for (final h in healthLabels.keys)
                          if ((health[h] ?? 0) > 0)
                            Expanded(
                              flex: health[h]!,
                              child: ColoredBox(color: healthColors[h]!),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    for (final h in healthLabels.keys)
                      if ((health[h] ?? 0) > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: healthColors[h],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${healthLabels[h]} ${health[h]}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: BioTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                  ],
                ),
              ],
            ],
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
            SpeciesReferencePhotos(
              name: species['scientificName'] as String? ?? '',
            ),
          ],
        ),
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(fontSize: 12.5, color: color)),
      ],
    ),
  );
}
