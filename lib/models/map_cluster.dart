import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class SpecimenCluster {
  SpecimenCluster(this.items);
  final List<Map<String, dynamic>> items;
  LatLng get center => LatLng(
    items.fold<double>(0, (sum, item) => sum + (item['latitude'] as num)) /
        items.length,
    items.fold<double>(0, (sum, item) => sum + (item['longitude'] as num)) /
        items.length,
  );
}

List<SpecimenCluster> clusterSpecimens(
  List<Map<String, dynamic>> items,
  double zoom,
) {
  final cell = 360 / math.pow(2, zoom.floor()) * 40 / 256;
  final groups = <String, List<Map<String, dynamic>>>{};
  for (final item in items) {
    final lat = item['latitude'], lon = item['longitude'];
    if (lat is! num || lon is! num || !lat.isFinite || !lon.isFinite) continue;
    final key = '${(lat / cell).floor()}:${(lon / cell).floor()}';
    groups.putIfAbsent(key, () => []).add(item);
  }
  return groups.values.map(SpecimenCluster.new).toList();
}
