import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

enum Verification { verified, unverified, failed, processing }

extension VerificationLabel on Verification {
  String get label => switch (this) {
    Verification.verified => 'Verificada',
    Verification.unverified => 'No verificada',
    Verification.failed => 'Fallida',
    Verification.processing => 'Procesando',
  };
}

class LocalPhoto {
  const LocalPhoto(this.bytes, this.name, this.mimeType);
  final Uint8List bytes;
  final String name;
  final String mimeType;
}

class Sighting {
  const Sighting({
    required this.id,
    required this.species,
    required this.photo,
    required this.point,
    required this.date,
    required this.status,
    this.confidence,
    this.animal = false,
    this.published = false,
    this.reviewRequested = false,
    this.retryAt,
  });
  final String id, species, photo;
  final LatLng point;
  final DateTime date;
  final Verification status;
  final double? confidence;
  final bool animal, published, reviewRequested;
  final DateTime? retryAt;
  bool get canPublish =>
      status == Verification.verified || status == Verification.unverified;
  bool get canRequestReview =>
      status == Verification.unverified && !reviewRequested;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.date,
    this.text = '',
    this.images = const [],
    this.avatar,
    this.sighting,
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
  });
  final String id, authorId, authorName, title, text;
  final DateTime date;
  final List<String> images;
  final String? avatar;
  final Sighting? sighting;
  final int likes, comments;
  final bool liked;
}

class PostDraft {
  const PostDraft({
    required this.title,
    this.text = '',
    this.photos = const [],
    this.retainedImages = const [],
    this.sighting,
  });
  final String title, text;
  final List<LocalPhoto> photos;
  final List<String> retainedImages;
  final Sighting? sighting;
  String? validate() {
    if (title.trim().isEmpty) return 'Escribe un título para la publicación.';
    if (photos.length + retainedImages.length > 10) {
      return 'Puedes incluir hasta diez imágenes.';
    }
    if (sighting?.canPublish == false) {
      return 'Una observación fallida no se puede publicar.';
    }
    return null;
  }
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.date,
    this.parentId,
  });
  final String id, authorId, authorName, text;
  final DateTime date;
  final String? parentId;
}

class FeedPage {
  const FeedPage(this.items, {this.nextCursor});
  final List<CommunityPost> items;
  final String? nextCursor;
}

class CampusZone {
  const CampusZone(this.id, this.name, this.points, {this.interest = false});
  final String id, name;
  final List<LatLng> points;
  final bool interest;
}

class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.period,
    required this.progress,
    required this.target,
    required this.xp,
    this.endsAt,
    this.zone,
  });
  final String id, title, description, period;
  final int progress, target, xp;
  final DateTime? endsAt;
  final CampusZone? zone;
  bool get completed => progress >= target;
}

class Curiosity {
  const Curiosity(
    this.title,
    this.description, {
    this.images = const [],
    this.zone,
  });
  final String title, description;
  final List<String> images;
  final CampusZone? zone;
}

class ProgressSummary {
  const ProgressSummary({
    required this.xp,
    required this.level,
    this.missions = const [],
    this.achievements = const [],
    this.curiosity,
  });
  final int xp, level;
  final List<Mission> missions, achievements;
  final Curiosity? curiosity;
}
