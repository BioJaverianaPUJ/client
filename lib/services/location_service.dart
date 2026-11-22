import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'community_repository.dart';

class LocationService {
  static Future<void> ensurePermission() async {
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
  }

  static Future<Position> current() async {
    await ensurePermission();
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  static Future<Position> precise({void Function(Position)? onProgress}) async {
    await ensurePermission();
    if (await Geolocator.getLocationAccuracy() ==
        LocationAccuracyStatus.reduced) {
      throw const FeatureUnavailable(
        'Activa Ubicación precisa en los permisos de BioJaveriana. La ubicación aproximada no permite registrar una observación.',
      );
    }
    return waitForPrecisePosition(
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      ),
      onProgress: onProgress,
    );
  }

  static Future<Position> waitForPrecisePosition(
    Stream<Position> positions, {
    Duration timeout = const Duration(seconds: 40),
    DateTime Function()? now,
    void Function(Position)? onProgress,
  }) async {
    final clock = now ?? DateTime.now;
    final result = Completer<Position>();
    double? best;
    final timer = Timer(timeout, () {
      if (!result.isCompleted) {
        result.completeError(
          FeatureUnavailable(
            'No se alcanzó la precisión de 5 m${best == null ? '' : ' (mejor lectura: ${best!.toStringAsFixed(1)} m)'}. '
            'La foto se conserva. Activa Ubicación precisa y reintenta desde el mismo lugar; si te desplazas, toma otra foto.',
          ),
        );
      }
    });
    final subscription = positions.listen(
      (position) {
        final age = clock().difference(position.timestamp);
        if (result.isCompleted ||
            !position.accuracy.isFinite ||
            position.accuracy < 0 ||
            !position.latitude.isFinite ||
            !position.longitude.isFinite ||
            position.latitude.abs() > 90 ||
            position.longitude.abs() > 180 ||
            age > const Duration(seconds: 15) ||
            age.isNegative) {
          return;
        }
        if (best == null || position.accuracy < best!) best = position.accuracy;
        onProgress?.call(position);
        if (position.accuracy <= 5) result.complete(position);
      },
      onError: (Object error, StackTrace stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      },
      onDone: () {
        if (!result.isCompleted) {
          result.completeError(
            const FeatureUnavailable(
              'Se interrumpió la ubicación. Reintenta sin moverte del lugar de la fotografía.',
            ),
          );
        }
      },
    );
    try {
      return await result.future;
    } finally {
      timer.cancel();
      await subscription.cancel();
    }
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
