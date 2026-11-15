import 'package:flutter/widgets.dart';

import 'bio_category.dart';

@immutable
class Species {
  const Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.icon,
    required this.zone,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final BioCategory category;
  final IconData icon;
  final String zone;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();

    return normalized.isEmpty ||
        commonName.toLowerCase().contains(normalized) ||
        scientificName.toLowerCase().contains(normalized);
  }
}
