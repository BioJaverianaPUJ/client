import 'package:latlong2/latlong.dart';
import '../models/community.dart';
import 'api_client.dart';
import '../config/campus_reference.dart';
import 'location_service.dart';
import 'community_repository.dart';

/// Observations have an independent contract from the social feed.
class ObservationRepository extends CommunityRepository {
  ObservationRepository(this.api);
  final ApiClient api;
  @override
  bool get observationsAvailable => true;

  static Sighting decode(Map<String, dynamic> json, {String? jobStatus}) {
    final score = json['certainty'];
    return Sighting(
      id: json['id'] as String,
      species:
          json['speciesCommonName'] as String? ?? 'Identificación pendiente',
      photo: json['imageUrl'] as String? ?? '',
      point: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      date: DateTime.parse(json['createdAt'] as String),
      // checked means recognition completed; it does NOT certify RF-14.
      status: jobStatus == 'FAILED'
          ? Verification.failed
          : json['checked'] == true
          ? Verification.unverified
          : Verification.processing,
      confidence: score is num && score >= 0 && score <= 1
          ? score.toDouble()
          : null,
      animal: json['observationType'] == 'ANIMAL',
      reviewRequested: json['revisionRequested'] == true,
    );
  }

  @override
  Future<List<Sighting>> sightings() async {
    final items = <Sighting>[];
    var page = 0;
    var pages = 1;
    do {
      final result = await api.get('/observations?page=$page&size=100');
      for (final raw in result['content'] as List) {
        final row = raw as Map<String, dynamic>;
        // List DTO omits failed jobs. Resolve unchecked items using their job.
        items.add(
          row['checked'] == true
              ? decode(row)
              : await refreshSighting(row['id'] as String),
        );
      }
      pages = (result['totalPages'] as num).toInt();
      page++;
    } while (page < pages);
    return items;
  }

  @override
  Future<Sighting> refreshSighting(String id) async {
    final result = await api.get(
      '/observations/${Uri.encodeComponent(id)}/job-status',
    );
    return decode(
      result['observation'] as Map<String, dynamic>,
      jobStatus: result['status'] as String,
    );
  }

  // A published server boundary must replace this reference when RF-57 is exposed.
  @override
  Future<List<LatLng>> campusBoundary() async => campusReference;

  @override
  Future<void> requestReview(String id) async {
    await api.post('/observations/${Uri.encodeComponent(id)}/revision-request');
  }

  @override
  Future<Sighting> submit(
    LocalPhoto photo,
    LatLng point,
    double accuracy,
    DateTime capturedAt,
  ) async {
    final boundary = await campusBoundary();
    if (!accuracy.isFinite ||
        accuracy > 5 ||
        accuracy < 0 ||
        !LocationService.inside(point, boundary)) {
      throw const FeatureUnavailable(
        'La captura debe estar dentro del campus y tener una ubicación precisa.',
      );
    }
    final recent = await api.get('/observations?page=0&size=1');
    final items = recent['content'] as List;
    if (items.isNotEmpty) {
      final previous = DateTime.parse(items.first['createdAt'] as String);
      if (DateTime.now().toUtc().difference(previous) <
          const Duration(minutes: 5)) {
        throw const FeatureUnavailable(
          'Espera cinco minutos desde tu última observación antes de enviar otra.',
        );
      }
    }
    final signed = await api.post(
      '/observations/upload-presign',
      body: {'contentType': photo.mimeType},
    );
    await api.uploadSignedPhoto(photo, signed);
    final result = await api.post(
      '/observations',
      body: {
        'referencePictureKey': signed['key'],
        'latitude': point.latitude,
        'longitude': point.longitude,
        'waitTimeoutSeconds': 0,
      },
    );
    return decode(
      result['observation'] as Map<String, dynamic>,
      jobStatus: result['status'] as String,
    );
  }
}
