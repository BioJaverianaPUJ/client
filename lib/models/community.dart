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
    this.similarity,
    this.specimen,
    this.animal = false,
    this.published = false,
    this.reviewRequested = false,
    this.retryAt,
  });
  final String id, species, photo;
  final LatLng point;
  final DateTime date;
  final Verification status;
  final double? confidence, similarity;
  final Map<String, dynamic>? specimen;
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
    this.observationId,
    this.dislikes = 0,
    this.disliked = false,
    this.likes = 0,
    this.comments = 0,
    this.liked = false,
  });
  final String id, authorId, authorName, title, text;
  final DateTime date;
  final List<String> images;
  final String? avatar;
  final Sighting? sighting;
  final String? observationId;
  final int likes, dislikes, comments;
  final bool disliked;
  final bool liked;

  CommunityPost copyWith({
    int? likes,
    int? dislikes,
    int? comments,
    bool? liked,
    bool? disliked,
  }) => CommunityPost(
    id: id,
    authorId: authorId,
    authorName: authorName,
    title: title,
    date: date,
    text: text,
    images: images,
    avatar: avatar,
    sighting: sighting,
    observationId: observationId,
    likes: likes ?? this.likes,
    dislikes: dislikes ?? this.dislikes,
    comments: comments ?? this.comments,
    liked: liked ?? this.liked,
    disliked: disliked ?? this.disliked,
  );
}

class PostDraft {
  const PostDraft({
    required this.title,
    this.text = '',
    this.photos = const [],
    this.retainedImages = const [],
    this.sighting,
    this.observationId,
  });
  final String title, text;
  final List<LocalPhoto> photos;
  final List<String> retainedImages;
  final Sighting? sighting;
  final String? observationId;
  String? validate() {
    if (title.trim().isEmpty) return 'Escribe un título para la publicación.';
    if (title.trim().length > 200 || text.trim().length > 200) {
      return 'El título y el texto admiten hasta 200 caracteres cada uno.';
    }
    if (photos.length + retainedImages.length > 10) {
      return 'Puedes incluir hasta diez imágenes.';
    }
    if (sighting?.canPublish == false) {
      return 'Una observación fallida no se puede publicar.';
    }
    return null;
  }
}

/// Resumen de una reacción (emoji) de un comentario y quiénes la usaron.
class CommentReactionCount {
  const CommentReactionCount(this.emoji, this.count, [this.userIds = const []]);
  final String emoji;
  final int count;
  final List<String> userIds;
}

class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.date,
    this.reactions = 0,
    this.parentId,
    this.avatar,
    this.reactionSummary = const [],
  });
  final String id, authorId, authorName, text;
  final DateTime date;
  final String? parentId;
  final int reactions;
  final String? avatar;

  /// Desglose por emoji. Vacío cuando el servidor solo envió el total.
  final List<CommentReactionCount> reactionSummary;

  /// Reacción del usuario indicado, si existe.
  String? reactionOf(String? userId) {
    if (userId == null) return null;
    for (final r in reactionSummary) {
      if (r.userIds.contains(userId)) return r.emoji;
    }
    return null;
  }

  /// Copia con la reacción de [userId] cambiada a [emoji] (null la retira).
  PostComment withReaction(String userId, String? emoji) {
    final previous = reactionOf(userId);
    final summary = <CommentReactionCount>[];
    for (final r in reactionSummary) {
      final ids = r.userIds.where((id) => id != userId).toList();
      if (r.emoji == emoji) ids.add(userId);
      if (ids.isNotEmpty || (r.count - r.userIds.length) > 0) {
        summary.add(
          CommentReactionCount(
            r.emoji,
            ids.length + (r.count - r.userIds.length),
            ids,
          ),
        );
      }
    }
    if (emoji != null && !summary.any((r) => r.emoji == emoji)) {
      summary.add(CommentReactionCount(emoji, 1, [userId]));
    }
    final delta = (emoji != null ? 1 : 0) - (previous != null ? 1 : 0);
    return PostComment(
      id: id,
      authorId: authorId,
      authorName: authorName,
      text: text,
      date: date,
      parentId: parentId,
      avatar: avatar,
      reactions: reactions + delta < 0 ? 0 : reactions + delta,
      reactionSummary: summary,
    );
  }
}

class FeedPage {
  const FeedPage(this.items, {this.nextCursor, this.total});
  final List<CommunityPost> items;
  final String? nextCursor;

  /// Total de publicaciones según el servidor, si lo informa.
  final int? total;
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
    this.completedByServer,
  });
  final String id, title, description, period;
  final int progress, target, xp;
  final DateTime? endsAt;
  final CampusZone? zone;
  final bool? completedByServer;
  bool get completed => completedByServer ?? (target > 0 && progress >= target);
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
    this.nextLevelXp,
    this.levelProgress,
    this.missionsAvailable = true,
  });
  final int xp, level;
  final List<Mission> missions, achievements;
  final Curiosity? curiosity;
  final int? nextLevelXp;
  final double? levelProgress;
  final bool missionsAvailable;
}

class XpHistoryEntry {
  const XpHistoryEntry({
    required this.id,
    required this.amount,
    required this.reason,
    required this.totalAfter,
    required this.levelAfter,
    required this.date,
  });
  final String id, reason;
  final int amount, totalAfter, levelAfter;
  final DateTime date;
}

class XpHistoryPage {
  const XpHistoryPage(this.items, {required this.hasMore});
  final List<XpHistoryEntry> items;
  final bool hasMore;
}

/// Persona que se puede mencionar con @ en un comentario.
class MentionUser {
  const MentionUser({
    required this.id,
    required this.username,
    this.name = '',
    this.avatar,
  });
  final String id, username, name;
  final String? avatar;
}
