import 'package:flutter/material.dart';

/// Grupo visual de una especie: define el ícono y el color de su insignia.
class SpeciesGroup {
  const SpeciesGroup(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

const _mdi = 'MaterialDesignIcons';

abstract final class SpeciesGroups {
  static const conifer = SpeciesGroup(
    'Conífera',
    IconData(0xf0405, fontFamily: _mdi),
    Color(0xFF7FC4B0),
  );
  static const palm = SpeciesGroup(
    'Palma',
    IconData(0xf1055, fontFamily: _mdi),
    Color(0xFFE3C46B),
  );
  static const tree = SpeciesGroup(
    'Árbol',
    IconData(0xf0531, fontFamily: _mdi),
    Color(0xFF9CCB72),
  );
  static const lobedTree = SpeciesGroup(
    'Árbol',
    IconData(0xf0c93, fontFamily: _mdi),
    Color(0xFFE59A6A),
  );
  static const flower = SpeciesGroup(
    'Planta con flor',
    IconData(0xf024a, fontFamily: _mdi),
    Color(0xFFE79BB8),
  );
  static const orchid = SpeciesGroup(
    'Orquídea',
    IconData(0xf09f1, fontFamily: _mdi),
    Color(0xFFC4A3E8),
  );
  static const fruit = SpeciesGroup(
    'Frutal',
    IconData(0xf1042, fontFamily: _mdi),
    Color(0xFFF0A07A),
  );
  static const grass = SpeciesGroup(
    'Pasto',
    IconData(0xf1510, fontFamily: _mdi),
    Color(0xFFC9D86E),
  );
  static const succulent = SpeciesGroup(
    'Suculenta',
    IconData(0xf0db5, fontFamily: _mdi),
    Color(0xFF8FC9A0),
  );
  static const fern = SpeciesGroup(
    'Helecho',
    IconData(0xf0e66, fontFamily: _mdi),
    Color(0xFF6FBF8E),
  );
  static const fungus = SpeciesGroup(
    'Hongo',
    IconData(0xf07e0, fontFamily: _mdi),
    Color(0xFFD9B48F),
  );
  static const bird = SpeciesGroup(
    'Ave',
    IconData(0xf15c6, fontFamily: _mdi),
    Color(0xFF8CC8E8),
  );
  static const owl = SpeciesGroup(
    'Ave rapaz',
    IconData(0xf03d2, fontFamily: _mdi),
    Color(0xFFB8A6E0),
  );
  static const duck = SpeciesGroup(
    'Ave acuática',
    IconData(0xf01e5, fontFamily: _mdi),
    Color(0xFF7DB8E0),
  );
  static const butterfly = SpeciesGroup(
    'Mariposa',
    IconData(0xf158a, fontFamily: _mdi),
    Color(0xFFF2B562),
  );
  static const bee = SpeciesGroup(
    'Abeja',
    IconData(0xf0fa1, fontFamily: _mdi),
    Color(0xFFF2CF5B),
  );
  static const ladybug = SpeciesGroup(
    'Escarabajo',
    IconData(0xf082d, fontFamily: _mdi),
    Color(0xFFEF8B7A),
  );
  static const insect = SpeciesGroup(
    'Insecto',
    IconData(0xf0a30, fontFamily: _mdi),
    Color(0xFFE8A86A),
  );
  static const spider = SpeciesGroup(
    'Arácnido',
    IconData(0xf11ea, fontFamily: _mdi),
    Color(0xFFBFA58A),
  );
  static const snail = SpeciesGroup(
    'Molusco',
    IconData(0xf1677, fontFamily: _mdi),
    Color(0xFFCFB98F),
  );
  static const rodent = SpeciesGroup(
    'Roedor',
    IconData(0xf1327, fontFamily: _mdi),
    Color(0xFFD2A97C),
  );
  static const bat = SpeciesGroup(
    'Murciélago',
    IconData(0xf0b5f, fontFamily: _mdi),
    Color(0xFFA9A3D6),
  );
  static const rabbit = SpeciesGroup(
    'Conejo',
    IconData(0xf0907, fontFamily: _mdi),
    Color(0xFFE0C1A0),
  );
  static const cat = SpeciesGroup(
    'Felino',
    IconData(0xf011b, fontFamily: _mdi),
    Color(0xFFE7B07A),
  );
  static const dog = SpeciesGroup(
    'Cánido',
    IconData(0xf0a43, fontFamily: _mdi),
    Color(0xFFD9A77F),
  );
  static const reptile = SpeciesGroup(
    'Reptil',
    IconData(0xf150e, fontFamily: _mdi),
    Color(0xFFA6CF7A),
  );
  static const fish = SpeciesGroup(
    'Pez',
    IconData(0xf023a, fontFamily: _mdi),
    Color(0xFF7FC0D8),
  );
  static const animal = SpeciesGroup(
    'Animal',
    IconData(0xf03e9, fontFamily: _mdi),
    Color(0xFFE5B27A),
  );
  static const plant = SpeciesGroup(
    'Planta',
    IconData(0xf032a, fontFamily: _mdi),
    Color(0xFFB5D57E),
  );

  static const _byFamily = <String, SpeciesGroup>{
    // Coníferas
    'pinaceae': conifer, 'cupressaceae': conifer, 'araucariaceae': conifer,
    'podocarpaceae': conifer, 'taxaceae': conifer,
    // Palmas
    'arecaceae': palm,
    // Árboles de hoja lobulada o compuesta llamativa
    'sapindaceae': lobedTree, 'platanaceae': lobedTree, 'araliaceae': lobedTree,
    'malvaceae': lobedTree,
    // Árboles
    'fagaceae': tree, 'betulaceae': tree, 'juglandaceae': tree,
    'salicaceae': tree, 'meliaceae': tree, 'myrtaceae': tree, 'fabaceae': tree,
    'euphorbiaceae': tree, 'oleaceae': tree, 'cunoniaceae': tree,
    'moraceae': tree, 'lauraceae': tree, 'magnoliaceae': tree,
    'primulaceae': tree, 'clusiaceae': tree, 'escalloniaceae': tree,
    'winteraceae': tree, 'urticaceae': tree, 'proteaceae': tree,
    'casuarinaceae': tree, 'adoxaceae': tree, 'viburnaceae': tree,
    'bignoniaceae': tree, 'anacardiaceae': tree, 'combretaceae': tree,
    'ulmaceae': tree, 'cannabaceae': tree, 'pittosporaceae': tree,
    // Flores
    'asteraceae': flower, 'rosaceae': flower, 'bromeliaceae': flower,
    'ericaceae': flower, 'onagraceae': flower, 'begoniaceae': flower,
    'melastomataceae': flower, 'hydrangeaceae': flower, 'lamiaceae': flower,
    'verbenaceae': flower, 'solanaceae': flower, 'acanthaceae': flower,
    'geraniaceae': flower, 'balsaminaceae': flower, 'amaryllidaceae': flower,
    'iridaceae': flower, 'liliaceae': flower, 'tropaeolaceae': flower,
    'scrophulariaceae': flower, 'plantaginaceae': flower, 'apocynaceae': flower,
    'nyctaginaceae': flower, 'malpighiaceae': flower, 'gesneriaceae': flower,
    'zingiberaceae': flower, 'heliconiaceae': flower, 'cannaceae': flower,
    'orchidaceae': orchid,
    // Frutales
    'rutaceae': fruit, 'passifloraceae': fruit, 'caricaceae': fruit,
    'annonaceae': fruit, 'musaceae': fruit, 'actinidiaceae': fruit,
    // Pastos
    'poaceae': grass, 'cyperaceae': grass, 'juncaceae': grass,
    // Suculentas
    'cactaceae': succulent, 'crassulaceae': succulent,
    'asparagaceae': succulent, 'aloaceae': succulent, 'agavaceae': succulent,
    // Helechos
    'cyatheaceae': fern, 'dicksoniaceae': fern, 'polypodiaceae': fern,
    'pteridaceae': fern, 'blechnaceae': fern, 'dryopteridaceae': fern,
    'aspleniaceae': fern, 'equisetaceae': fern,
    // Hongos
    'agaricaceae': fungus, 'polyporaceae': fungus, 'psathyrellaceae': fungus,
    'marasmiaceae': fungus,
    // Aves
    'trochilidae': bird, 'turdidae': bird, 'passerellidae': bird,
    'emberizidae': bird, 'tyrannidae': bird, 'thraupidae': bird,
    'columbidae': bird, 'picidae': bird, 'hirundinidae': bird,
    'icteridae': bird, 'fringillidae': bird, 'psittacidae': bird,
    'parulidae': bird, 'troglodytidae': bird, 'mimidae': bird,
    'cardinalidae': bird, 'corvidae': bird, 'furnariidae': bird,
    'accipitridae': owl, 'falconidae': owl, 'strigidae': owl,
    'tytonidae': owl, 'cathartidae': owl,
    'anatidae': duck, 'ardeidae': duck, 'rallidae': duck,
    'threskiornithidae': duck,
    // Insectos y otros invertebrados
    'nymphalidae': butterfly, 'pieridae': butterfly, 'papilionidae': butterfly,
    'lycaenidae': butterfly, 'hesperiidae': butterfly, 'riodinidae': butterfly,
    'saturniidae': butterfly, 'sphingidae': butterfly, 'erebidae': butterfly,
    'apidae': bee, 'vespidae': bee, 'halictidae': bee, 'megachilidae': bee,
    'formicidae': insect,
    'coccinellidae': ladybug, 'scarabaeidae': ladybug, 'chrysomelidae': ladybug,
    'curculionidae': ladybug, 'carabidae': ladybug,
    'araneidae': spider, 'salticidae': spider, 'theridiidae': spider,
    'lycosidae': spider, 'pholcidae': spider,
    'helicidae': snail, 'bulimulidae': snail, 'limacidae': snail,
    'veronicellidae': snail,
    // Mamíferos
    'sciuridae': rodent, 'muridae': rodent, 'cricetidae': rodent,
    'didelphidae': rodent, 'caviidae': rodent,
    'phyllostomidae': bat, 'vespertilionidae': bat, 'molossidae': bat,
    'leporidae': rabbit,
    'felidae': cat,
    'canidae': dog,
    // Reptiles, anfibios y peces
    'colubridae': reptile, 'dipsadidae': reptile, 'viperidae': reptile,
    'tropiduridae': reptile, 'gymnophthalmidae': reptile, 'anolidae': reptile,
    'dactyloidae': reptile, 'iguanidae': reptile, 'testudinidae': reptile,
    'hylidae': animal, 'craugastoridae': animal, 'bufonidae': animal,
    'cyprinidae': fish, 'poeciliidae': fish, 'cichlidae': fish,
  };

  /// Pistas por nombre común cuando la familia no está en la tabla.
  static const _byKeyword = <String, SpeciesGroup>{
    'pino': conifer, 'ciprés': conifer, 'cipres': conifer, 'araucaria': conifer,
    'palma': palm, 'palmera': palm,
    'orquídea': orchid, 'orquidea': orchid,
    'rosa': flower, 'flor': flower, 'margarita': flower, 'girasol': flower,
    'helecho': fern, 'pasto': grass, 'hierba': grass, 'bambú': grass,
    'cactus': succulent, 'agave': succulent, 'sábila': succulent,
    'naranjo': fruit, 'naranja': fruit, 'limón': fruit, 'limon': fruit,
    'mandarina': fruit,
    'curuba': fruit, 'feijoa': fruit, 'guayabo': fruit, 'guayaba': fruit,
    'aguacate': fruit,
    'colibrí': bird, 'colibri': bird, 'copetón': bird, 'copeton': bird,
    'mirla': bird, 'paloma': bird, 'tórtola': bird, 'tortola': bird,
    'gorrión': bird, 'pájaro': bird, 'ave': bird, 'carpintero': bird,
    'búho': owl, 'buho': owl, 'lechuza': owl, 'halcón': owl, 'gavilán': owl,
    'pato': duck, 'garza': duck,
    'mariposa': butterfly, 'polilla': butterfly,
    'abeja': bee, 'avispa': bee, 'abejorro': bee,
    'mariquita': ladybug, 'cucarrón': ladybug, 'escarabajo': ladybug,
    'hormiga': insect, 'araña': spider, 'caracol': snail, 'babosa': snail,
    'ardilla': rodent, 'ratón': rodent, 'rata': rodent, 'zarigüeya': rodent,
    'chucha': rodent, 'curí': rodent,
    'murciélago': bat, 'murcielago': bat, 'conejo': rabbit,
    'gato': cat, 'perro': dog,
    'serpiente': reptile, 'culebra': reptile, 'lagartija': reptile,
    'rana': animal, 'sapo': animal, 'pez': fish,
    'roble': tree, 'eucalipto': tree, 'cedro': tree, 'nogal': tree,
    'sauce': tree, 'urapán': tree, 'urapan': tree, 'aliso': tree,
    'arrayán': tree, 'caucho': tree, 'acacia': tree, 'guayacán': tree,
    'chicalá': tree, 'jazmín': flower, 'sietecueros': flower,
    'mano de oso': lobedTree, 'arce': lobedTree,
  };

  static SpeciesGroup of(Map<String, dynamic> species) {
    final family = '${species['family'] ?? ''}'.trim().toLowerCase();
    final byFamily = _byFamily[family];
    if (byFamily != null) return byFamily;
    final names = [
      species['commonName'],
      species['scientificName'],
    ].whereType<String>().join(' ').toLowerCase();
    for (final entry in _byKeyword.entries) {
      final word = RegExp(
        '(^|[^a-záéíóúñü])${RegExp.escape(entry.key)}(\$|[^a-záéíóúñü])',
      );
      if (word.hasMatch(names)) {
        return entry.value;
      }
    }
    final animalFlag = species['animal'] == true ||
        '${species['kingdom'] ?? ''}'.toLowerCase() == 'animalia';
    return animalFlag ? animal : plant;
  }
}

/// Insignia de la especie: ícono distinto y color propio por grupo, para
/// diferenciar a simple vista árboles, flores, palmas, aves, insectos, etc.
class SpeciesSymbol extends StatelessWidget {
  const SpeciesSymbol(this.species, {super.key, this.size = 48});
  final Map<String, dynamic> species;
  final double size;
  @override
  Widget build(BuildContext context) {
    final group = SpeciesGroups.of(species);
    return Tooltip(
      message: group.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * .36),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              group.color.withValues(alpha: .34),
              group.color.withValues(alpha: .14),
            ],
          ),
          border: Border.all(color: group.color.withValues(alpha: .55)),
          boxShadow: [
            BoxShadow(
              color: group.color.withValues(alpha: .14),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(group.icon, size: size * .52, color: group.color),
      ),
    );
  }
}
