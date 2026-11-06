/// Public CARTO Basemaps key, never a private account/API credential.
class MapConfig {
  static const cartoKey = String.fromEnvironment('CARTO_BASEMAP_KEY');
  static bool get usesCarto => cartoKey.trim().isNotEmpty;
  static String get tileUrl => usesCarto
      ? 'https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=${Uri.encodeQueryComponent(cartoKey.trim())}'
      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
