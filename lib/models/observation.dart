import 'package:flutter/widgets.dart';

import 'bio_category.dart';

@immutable
class Observation {
  const Observation({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.category,
    required this.icon,
    required this.date,
    required this.location,
  });

  final String id;
  final String commonName;
  final String scientificName;
  final BioCategory category;
  final IconData icon;
  final String date;
  final String location;
}
