import 'package:flutter/material.dart';
import '../theme/bio_theme.dart';
import 'bio_scene.dart';

/// Mini guía para tomar fotos que el modelo de reconocimiento entienda bien.
///
/// Basada en lo que recomiendan Pl@ntNet / iNaturalist (un solo organismo,
/// cerca, nítido, flores y frutos primero) y en los rasgos que se usan para
/// diferenciar plantas en el campus: espinas, tamaño de la hoja, nervadura y
/// borde de la hoja.
class PhotoCaptureGuide extends StatefulWidget {
  const PhotoCaptureGuide({super.key});
  @override
  State<PhotoCaptureGuide> createState() => _PhotoCaptureGuideState();
}

class _GuideCategory {
  const _GuideCategory(this.label, this.icon, this.tips);
  final String label;
  final IconData icon;
  final List<(IconData, String)> tips;
}

const _mdi = 'MaterialDesignIcons';

class _PhotoCaptureGuideState extends State<PhotoCaptureGuide> {
  bool _open = false;
  int _category = 0;

  static const _basics = [
    (Icons.center_focus_strong_outlined, 'Un solo ser vivo'),
    (Icons.wb_sunny_outlined, 'Luz natural'),
    (Icons.blur_off_outlined, 'Nítida'),
  ];

  static const _categories = [
    _GuideCategory('Hojas', IconData(0xf032a, fontFamily: _mdi), [
      (
        Icons.crop_free,
        'Una hoja completa, de la base a la punta, que llene casi toda la foto.',
      ),
      (
        Icons.zoom_in,
        'Que se vean el borde (liso o aserrado) y las nervaduras.',
      ),
      (
        Icons.report_gmailerrorred_outlined,
        'Si la planta tiene espinas, inclúyelas. No arranques la hoja.',
      ),
    ]),
    _GuideCategory('Flores y frutos', IconData(0xf024a, fontFamily: _mdi), [
      (
        Icons.star_outline,
        'Son lo que más ayuda a identificar: si hay, fotografíalos primero.',
      ),
      (
        Icons.flip_camera_android_outlined,
        'Toma la flor de frente y, si puedes, otra de lado.',
      ),
      (
        Icons.do_not_touch_outlined,
        'Evita que salgan tus dedos, macetas u otras plantas.',
      ),
    ]),
    _GuideCategory('Árboles', IconData(0xf0531, fontFamily: _mdi), [
      (
        Icons.nature_outlined,
        'Acércate a una rama baja con hojas: la copa lejana dice muy poco.',
      ),
      (
        Icons.texture_outlined,
        'La corteza ayuda solo como apoyo, no como única foto.',
      ),
      (
        Icons.wb_twilight_outlined,
        'No fotografíes contra el cielo: el contraluz oscurece las hojas.',
      ),
    ]),
    _GuideCategory('Animales', IconData(0xf03e9, fontFamily: _mdi), [
      (
        Icons.fit_screen_outlined,
        'Que el animal ocupe la mayor parte de la foto.',
      ),
      (
        Icons.pets_outlined,
        'Completo: sin cortar cabeza, alas, patas ni cola.',
      ),
      (
        Icons.flash_off_outlined,
        'A distancia segura, sin flash y sin perseguirlo.',
      ),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final category = _categories[_category];
    return BioGlassCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: BioTheme.lime,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cómo tomar una buena foto',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      _open ? 'Ocultar' : 'Ver guía',
                      style: const TextStyle(
                        color: BioTheme.lime,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? .5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: const Icon(
                        Icons.expand_more,
                        color: BioTheme.lime,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < _basics.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _BasicPill(_basics[i].$1, _basics[i].$2)),
                ],
              ],
            ),
            if (_open) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < _categories.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            _categories[i].icon,
                            size: 16,
                            color: _category == i
                                ? BioTheme.iconDark
                                : BioTheme.lime,
                          ),
                          showCheckmark: false,
                          label: Text(
                            _categories[i].label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _category == i
                                  ? BioTheme.iconDark
                                  : BioTheme.textPrimary,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          selected: _category == i,
                          onSelected: (_) => setState(() => _category = i),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final tip in category.tips)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, right: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: BioTheme.lime.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tip.$1, size: 16, color: BioTheme.lime),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tip.$2,
                            style: const TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 6),
                child: Text(
                  'La identificación es una sugerencia: compárala con las fotos de referencia de la especie.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: BioTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BasicPill extends StatelessWidget {
  const _BasicPill(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: BioTheme.backgroundDeep.withValues(alpha: .35),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: BioTheme.lime.withValues(alpha: .18)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: BioTheme.lime),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
