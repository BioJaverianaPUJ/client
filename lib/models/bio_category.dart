import 'package:flutter/widgets.dart';

import '../theme/bio_icons.dart';

enum BioCategory {
  all('Todos'),
  animals('Animales'),
  plants('Plantas'),
  trees('Árboles');

  const BioCategory(this.label);

  final String label;

  IconData get icon => switch (this) {
        BioCategory.all => BioIcons.leaf,
        BioCategory.animals => BioIcons.paw,
        BioCategory.plants => BioIcons.flowerOutline,
        BioCategory.trees => BioIcons.treeOutline,
      };

  bool includes(BioCategory category) =>
      this == BioCategory.all || this == category;
}
