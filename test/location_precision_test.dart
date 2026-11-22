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
  test(
    'waits for an accurate fresh fix instead of rejecting the first reading',
    () async {
      final readings = <double>[];
      final position = await LocationService.waitForPrecisePosition(
        Stream.fromIterable([fix(30), fix(8), fix(4)]),
        now: () => instant,
        onProgress: (p) => readings.add(p.accuracy),
      );
      expect(position.accuracy, 4);
      expect(readings, [30, 8, 4]);
    },
  );
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
  test('timeout cancels GPS and preserves the accuracy requirement', () async {
    var cancelled = false;
    final stream = StreamController<Position>(onCancel: () => cancelled = true);
    final pending = LocationService.waitForPrecisePosition(
      stream.stream,
      timeout: const Duration(milliseconds: 30),
      now: () => instant,
    );
    stream.add(fix(12));
    await expectLater(
      pending,
      throwsA(
        isA<FeatureUnavailable>().having(
          (e) => e.message,
          'message',
          contains('12.0 m'),
        ),
      ),
    );
    expect(cancelled, true);
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
