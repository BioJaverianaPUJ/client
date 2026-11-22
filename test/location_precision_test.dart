import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biojaveriana/services/location_service.dart';
import 'package:biojaveriana/services/community_repository.dart';

final instant = DateTime.utc(2026, 11, 22, 12);
Position fix(double accuracy, {DateTime? timestamp}) => Position(
  longitude: -74.065,
  latitude: 4.628,
  timestamp: timestamp ?? instant,
  accuracy: accuracy,
  altitude: 2600,
  altitudeAccuracy: 2,
  heading: 0,
  headingAccuracy: 1,
  speed: 0,
  speedAccuracy: 1,
);

void main() {
  test('accepts the first good reading without waiting for 5 m', () async {
    final readings = <double>[];
    final position = await LocationService.waitForPrecisePosition(
      Stream.fromIterable([fix(30), fix(8), fix(4)]),
      now: () => instant,
      onProgress: (p) => readings.add(p.accuracy),
    );
    expect(position.accuracy, 8);
    expect(readings, [30, 8]);
  });
  test('ignores stale, future and invalid fixes', () async {
    final readings = <double>[];
    final position = await LocationService.waitForPrecisePosition(
      Stream.fromIterable([
        fix(1, timestamp: instant.subtract(const Duration(minutes: 1))),
        fix(1, timestamp: instant.add(const Duration(seconds: 1))),
        fix(double.nan),
        fix(-1),
        fix(5),
      ]),
      now: () => instant,
      onProgress: (p) => readings.add(p.accuracy),
    );
    expect(position.accuracy, 5);
    expect(readings, [5]);
  });
  test('an imprecise GPS never blocks: uses the best reading', () async {
    var cancelled = false;
    final stream = StreamController<Position>(onCancel: () => cancelled = true);
    final pending = LocationService.waitForPrecisePosition(
      stream.stream,
      settle: const Duration(milliseconds: 30),
      now: () => instant,
    );
    stream.add(fix(80));
    stream.add(fix(45));
    stream.add(fix(60));
    expect((await pending).accuracy, 45);
    expect(cancelled, true);
    await stream.close();
  });
  test('fails only when no valid reading arrives', () async {
    final stream = StreamController<Position>();
    final pending = LocationService.waitForPrecisePosition(
      stream.stream,
      timeout: const Duration(milliseconds: 30),
      now: () => instant,
    );
    await expectLater(pending, throwsA(isA<FeatureUnavailable>()));
    await stream.close();
  });
  test('successful fix stops location subscription', () async {
    var cancelled = false;
    final stream = StreamController<Position>(onCancel: () => cancelled = true);
    final pending = LocationService.waitForPrecisePosition(
      stream.stream,
      now: () => instant,
    );
    stream.add(fix(3));
    expect((await pending).accuracy, 3);
    expect(cancelled, true);
    await stream.close();
  });
}
