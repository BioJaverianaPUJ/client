
import '../models/bio_category.dart';
import '../models/campus_location.dart';
import '../models/observation.dart';
import '../models/species.dart';
import '../theme/bio_icons.dart';

abstract final class MockData {
  static const userCampus = 'Campus Bogotá';

  static const recordsCount = 12;
  static const speciesCount = 9;
  static const zonesCount = 5;
  static const explorationProgress = 0.62;

  static const campusAnimals = 10;
  static const campusPlants = 18;
  static const campusTrees = 12;

  static final species = <Species>[
    Species(
      id: '1',
      commonName: 'Roble colombiano',
      scientificName: 'Quercus humboldtii',
      category: BioCategory.trees,
      icon: BioIcons.treeOutline,
      zone: 'Campus',
    ),
    Species(
      id: '2',
      commonName: 'Mirla grande',
      scientificName: 'Turdus fuscater',
      category: BioCategory.animals,
      icon: BioIcons.bird,
      zone: 'Campus',
    ),
    Species(
      id: '3',
      commonName: 'Ardilla',
      scientificName: 'Sciurus granatensis',
      category: BioCategory.animals,
      icon: BioIcons.paw,
      zone: 'Campus',
    ),
    Species(
      id: '4',
      commonName: 'Helecho',
      scientificName: 'Polypodiopsida',
      category: BioCategory.plants,
      icon: BioIcons.leaf,
      zone: 'Campus',
    ),
  ];

  static final observations = <Observation>[
    Observation(
      id: '1',
      commonName: 'Mirla grande',
      scientificName: 'Turdus fuscater',
      category: BioCategory.animals,
      icon: BioIcons.bird,
      date: '18 AGO',
      location: 'Zona verde central',
    ),
    Observation(
      id: '2',
      commonName: 'Roble colombiano',
      scientificName: 'Quercus humboldtii',
      category: BioCategory.trees,
      icon: BioIcons.treeOutline,
      date: '16 AGO',
      location: 'Sendero norte',
    ),
    Observation(
      id: '3',
      commonName: 'Margarita',
      scientificName: 'Bellis perennis',
      category: BioCategory.plants,
      icon: BioIcons.flowerOutline,
      date: '14 AGO',
      location: 'Jardines',
    ),
    Observation(
      id: '4',
      commonName: 'Copetón',
      scientificName: 'Zonotrichia capensis',
      category: BioCategory.animals,
      icon: BioIcons.bird,
      date: '11 AGO',
      location: 'Bosque del campus',
    ),
    Observation(
      id: '5',
      commonName: 'Sietecueros',
      scientificName: 'Tibouchina lepidota',
      category: BioCategory.trees,
      icon: BioIcons.treeOutline,
      date: '08 AGO',
      location: 'Zona de observación',
    ),
  ];

  static final campusLocations = <CampusLocation>[
    CampusLocation(
      id: '1',
      name: 'Zona verde central',
      subtitle: '5 especies registradas',
      category: BioCategory.trees,
      icon: BioIcons.treeOutline,
      top: 0.30,
      left: 0.27,
    ),
    CampusLocation(
      id: '2',
      name: 'Jardines',
      subtitle: '8 especies registradas',
      category: BioCategory.plants,
      icon: BioIcons.flowerOutline,
      top: 0.46,
      left: 0.66,
    ),
    CampusLocation(
      id: '3',
      name: 'Sendero norte',
      subtitle: '4 especies registradas',
      category: BioCategory.animals,
      icon: BioIcons.paw,
      top: 0.25,
      left: 0.69,
    ),
    CampusLocation(
      id: '4',
      name: 'Bosque del campus',
      subtitle: '11 especies registradas',
      category: BioCategory.trees,
      icon: BioIcons.treeOutline,
      top: 0.66,
      left: 0.29,
    ),
    CampusLocation(
      id: '5',
      name: 'Zona de observación',
      subtitle: '6 especies registradas',
      category: BioCategory.animals,
      icon: BioIcons.bird,
      top: 0.69,
      left: 0.65,
    ),
  ];
}
