import 'package:latlong2/latlong.dart';
import '../models/community.dart';

class FeatureUnavailable implements Exception {
  const FeatureUnavailable(this.message);
  final String message;
}

/// Boundary for services whose server contracts have not been published yet.
/// Replace this implementation when those contracts are available, not the UI.
class CommunityRepository {
  bool get available => false;
  bool get observationsAvailable => available;
  bool get observationDeletionAvailable => available;
  bool get observationRetryAvailable => available;
  Future<Sighting> refreshSighting(String id) => _pending();
  Future<T> _pending<T>() async => throw const FeatureUnavailable(
    'Esta función aún no está disponible. Tu información no se ha enviado.',
  );
  Future<FeedPage> feed({String? cursor, String? authorId}) => _pending();
  Future<CommunityPost> savePost(PostDraft draft, {String? id}) => _pending();
  Future<void> deletePost(String id) => _pending();
  Future<CommunityPost> like(String id, bool liked) => _pending();
  Future<List<PostComment>> comments(String postId) => _pending();
  Future<void> saveComment(
    String postId,
    String text, {
    String? id,
    String? parentId,
  }) => _pending();
  Future<void> deleteComment(String postId, String id) => _pending();
  Future<List<String>> reportReasons() => _pending();
  Future<void> report(
    String id, {
    required bool comment,
    required String reason,
    String? text,
  }) => _pending();
  Future<List<Sighting>> sightings() => _pending();
  Future<Sighting> submit(
    LocalPhoto photo,
    LatLng point,
    double accuracy,
    DateTime capturedAt,
  ) => _pending();
  Future<Sighting> retry(String id) => _pending();
  Future<void> requestReview(String id) => _pending();
  Future<void> deleteSighting(String id) => _pending();
  Future<List<LatLng>> campusBoundary() => _pending();
  Future<List<CampusZone>> zones() => _pending();
  Future<void> visit(LatLng point, double accuracy) => _pending();
  Future<ProgressSummary> progress({String? userId}) => _pending();
}
