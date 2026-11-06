import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'community_repository.dart';

class LocationService {
  static Future<Position> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const FeatureUnavailable(
        'Activa la ubicación del dispositivo para continuar.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const FeatureUnavailable(
        'El permiso de ubicación está bloqueado. Actívalo en los ajustes de BioJaveriana.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const FeatureUnavailable(
        'Necesitamos tu permiso de ubicación. Puedes seguir consultando el mapa sin mostrar tu posición.',
      );
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static bool inside(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    var inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i], b = polygon[j];
      final cross =
          (point.longitude - a.longitude) * (b.latitude - a.latitude) -
          (point.latitude - a.latitude) * (b.longitude - a.longitude);
      if (cross.abs() < 1e-12 &&
          point.longitude >=
              (a.longitude < b.longitude ? a.longitude : b.longitude) &&
          point.longitude <=
              (a.longitude > b.longitude ? a.longitude : b.longitude) &&
          point.latitude >=
              (a.latitude < b.latitude ? a.latitude : b.latitude) &&
          point.latitude <=
              (a.latitude > b.latitude ? a.latitude : b.latitude)) {
        return true;
      }
      if ((a.latitude > point.latitude) != (b.latitude > point.latitude) &&
          point.longitude <
              (b.longitude - a.longitude) *
                      (point.latitude - a.latitude) /
                      (b.latitude - a.latitude) +
                  a.longitude) {
        inside = !inside;
      }
    }
    return inside;
  }
}
