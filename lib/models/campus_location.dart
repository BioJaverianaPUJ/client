import 'package:flutter/widgets.dart';

import 'bio_category.dart';

@immutable
class CampusLocation {
  const CampusLocation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.top,
    required this.left,
  });

  final String id;
  final String name;
  final String subtitle;
  final BioCategory category;
  final IconData icon;
  final double top;
  final double left;
}
