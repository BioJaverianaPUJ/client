import 'dart:convert';
import 'package:biojaveriana/models/map_cluster.dart';
import 'dart:typed_data';
import 'package:biojaveriana/config/campus_reference.dart';
import 'package:biojaveriana/models/community.dart';
import 'package:biojaveriana/models/experience.dart';
import 'package:biojaveriana/services/api_client.dart';
import 'package:biojaveriana/services/observation_repository.dart';
import 'package:biojaveriana/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> observation(String id, bool checked) => {
  'id': id,
  'checked': checked,
  'latitude': 4.628,
  'longitude': -74.064,
  'createdAt': '2026-11-05T12:00:00Z',
  'speciesCommonName': 'Roble',
  'certainty': .99,
  'observationType': 'PLANT',
  'revisionRequested': false,
};
void main() {
  test('RF-36 exponential thresholds, including fractional boundaries', () {
    expect(Experience(0).level, 1);
    expect(Experience(9).nextThreshold, 10);
    expect(Experience(10).level, 2);
    expect(Experience(15).level, 3);
    expect(Experience(22).level, 3);
    expect(Experience(23).level, 4);
    expect(Experience(23).nextThreshold, 34);
    expect(Experience(34).level, 5);
    expect(() => Experience(-1), throwsArgumentError);
  });
  test('checked is not verified; processing and failure cannot publish', () {
    expect(
      ObservationRepository.decode(observation('a', true)).status,
      Verification.unverified,
    );
    expect(
      ObservationRepository.decode(observation('a', false)).canPublish,
      false,
    );
    expect(
      ObservationRepository.decode(
        observation('a', false),
        jobStatus: 'FAILED',
      ).status,
      Verification.failed,
    );
  });
  test(
    'observation pagination uses root metadata and resolves failed jobs',
    () async {
      final paths = <String>[];
      final api = ApiClient(
        httpClient: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer test-token');
          paths.add(r.url.path);
          if (r.url.path.endsWith('/job-status')) {
            return http.Response(
              jsonEncode({
                'status': 'FAILED',
                'observation': observation('failed', false),
              }),
              200,
            );
          }
          final page = r.url.queryParameters['page'];
          return http.Response(
            jsonEncode({
              'content': [
                observation(page == '0' ? 'done' : 'failed', page == '0'),
              ],
              'totalPages': 2,
            }),
            200,
          );
        }),
      )..token = 'test-token';
      final result = await ObservationRepository(api).sightings();
      expect(result.map((s) => s.status), [
        Verification.unverified,
        Verification.failed,
      ]);
      expect(paths.last, endsWith('/failed/job-status'));
      api.close();
    },
  );
  test('signed upload never sends bearer and rejects insecure URLs', () async {
    var requests = 0;
    final api = ApiClient(
      httpClient: MockClient((r) async {
        requests++;
        expect(r.headers.containsKey('Authorization'), false);
        expect(r.method, 'PUT');
        expect(r.followRedirects, false);
        return http.Response('', 200);
      }),
    )..token = 'private-token';
    final photo = LocalPhoto(
      Uint8List.fromList([1, 2]),
      'photo.jpg',
      'image/jpeg',
    );
    await api.uploadSignedPhoto(photo, {
      'url': 'https://storage.example.test/photo',
      'method': 'PUT',
      'contentType': 'image/jpeg',
    });
    await expectLater(
      api.uploadSignedPhoto(photo, {
        'url': 'http://storage.example.test/photo',
        'method': 'PUT',
        'contentType': 'image/jpeg',
      }),
      throwsException,
    );
    expect(requests, 1);
    api.close();
  });
  test(
    'OSM perimeter surrounds main campus and excludes distant locations',
    () {
      expect(campusReference.length, 125);
      expect(
        LocationService.inside(const LatLng(4.6286, -74.0637), campusReference),
        true,
      );
      expect(
        LocationService.inside(const LatLng(4.65, -74.08), campusReference),
        false,
      );
    },
  );
  test(
    'capture uploads once, creates a non-blocking job and enforces cooldown',
    () async {
      var recent = false;
      final calls = <String>[];
      final api = ApiClient(
        httpClient: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}');
          if (r.url.path.endsWith('/upload-presign')) {
            return http.Response(
              jsonEncode({
                'url': 'https://storage.example.test/image',
                'method': 'PUT',
                'key': 'observations/u/photo',
                'contentType': 'image/jpeg',
              }),
              200,
            );
          }
          if (r.method == 'PUT') return http.Response('', 200);
          if (r.method == 'GET') {
            return http.Response(
              jsonEncode({
                'content': recent
                    ? [
                        {'createdAt': DateTime.now().toUtc().toIso8601String()},
                      ]
                    : [],
              }),
              200,
            );
          }
          expect(jsonDecode(r.body)['waitTimeoutSeconds'], 0);
          expect(
            jsonDecode(r.body)['referencePictureKey'],
            'observations/u/photo',
          );
          return http.Response(
            jsonEncode({
              'status': 'PENDING',
              'observation': observation('created', false),
            }),
            200,
          );
        }),
      );
      final repo = ObservationRepository(api);
      final photo = LocalPhoto(
        Uint8List.fromList([1]),
        'capture.jpg',
        'image/jpeg',
      );
      final result = await repo.submit(
        photo,
        const LatLng(4.6286, -74.0637),
        3,
        DateTime.now(),
      );
      expect(result.status, Verification.processing);
      expect(calls.length, 4);
      recent = true;
      await expectLater(
        repo.submit(photo, const LatLng(4.6286, -74.0637), 3, DateTime.now()),
        throwsException,
      );
      expect(calls.length, 5);
      await expectLater(
        repo.submit(photo, const LatLng(4.65, -74.08), 3, DateTime.now()),
        throwsException,
      );
      expect(calls.length, 5);
      api.close();
    },
  );
  test('map clusters preserve specimens and separate distant coordinates', () {
    final rows = [
      {'latitude': 4.628, 'longitude': -74.064},
      {'latitude': 4.628, 'longitude': -74.064},
      {'latitude': 4.63, 'longitude': -74.062},
    ];
    final clusters = clusterSpecimens(rows, 17);
    expect(clusters.length, 2);
    expect(clusters.first.items.length, 2);
    expect(clusters.fold<int>(0, (sum, c) => sum + c.items.length), 3);
  });
}
