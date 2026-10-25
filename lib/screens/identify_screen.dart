import 'package:flutter/material.dart';

import '../theme/bio_icons.dart';
import '../theme/bio_text_styles.dart';
import '../theme/bio_theme.dart';
import '../widgets/bio_action_card.dart';
import '../widgets/bio_badge.dart';
import '../widgets/bio_bottom_navigation.dart';
import '../widgets/bio_illustration.dart';
import '../widgets/bio_pressable.dart';
import '../widgets/bio_screen.dart';
import '../widgets/bio_section_header.dart';
import '../widgets/glass/deep_frost_glass.dart';
import '../widgets/glass/glass_icon.dart';
import '../widgets/glass/soft_frost_glass.dart';

class IdentifyScreen extends StatefulWidget {
  const IdentifyScreen({super.key});

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  bool _cameraActive = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return BioScreen(
      activeTab: BioTab.identify,
      decorations: [
        BioIllustration(
          asset: 'assets/illustrations/floral_frame.png',
          color: BioTheme.limeSoft,
          opacity: 0.10,
          top: 105,
          left: (screenWidth - 470) / 2,
          width: 470,
          height: 700,
        ),
      ],
      children: [
        const BioIntro(
          eyebrow: 'IDENTIFICA UNA ESPECIE',
          title: 'Descubre qué',
          accent: 'estás viendo.',
          description: 'Toma una foto y descubre qué animal, planta o árbol '
              'encontraste en el campus.',
        ),
        const SizedBox(height: 28),
        _CameraCard(
          active: _cameraActive,
          onCapture: () => setState(() => _cameraActive = !_cameraActive),
        ),
        const BioSectionHeader(title: 'OTRA OPCIÓN'),
        BioActionCard(
          leading: GlassIcon(
            icon: BioIcons.imageMultipleOutline,
            size: 52,
            iconSize: 22,
            strong: true,
          ),
          eyebrow: 'DESDE TU GALERÍA',
          title: 'Seleccionar una foto',
          description: 'Identifica una especie usando una imagen que ya '
              'tengas.',
          minHeight: 112,
          trailing: Icon(
            BioIcons.arrowRight,
            size: 21,
            color: BioTheme.limeSoft,
          ),
          onTap: () {},
        ),
        const BioSectionHeader(title: 'PUEDES IDENTIFICAR'),
        Row(
          children: [
            Expanded(
              child: _CategoryCard(
                icon: BioIcons.paw,
                title: 'Animales',
                description: 'Fauna del campus',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _CategoryCard(
                icon: BioIcons.flowerOutline,
                title: 'Plantas',
                description: 'Flora y especies',
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _CategoryCard(
                icon: BioIcons.treeOutline,
                title: 'Árboles',
                description: 'Especies arbóreas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SoftFrostGlass(
          borderRadius: 28,
          minHeight: 100,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(BioIcons.lightbulbOutline, size: 21, color: BioTheme.lime),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para obtener mejores resultados',
                      style: TextStyle(
                        color: BioTheme.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 5),
                    FractionallySizedBox(
                      widthFactor: 0.95,
                      child: Text(
                        'Acércate a la especie, utiliza buena iluminación y '
                        'procura que ocupe gran parte de la imagen.',
                        style: TextStyle(
                          color: BioTheme.textMuted,
                          fontSize: 9.5,
                          height: 14 / 9.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.active, required this.onCapture});

  final bool active;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return DeepFrostGlass(
      borderRadius: 36,
      height: 480,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  BioDot(size: 6),
                  SizedBox(width: 7),
                  Text(
                    'IDENTIFICACIÓN',
                    style: TextStyle(
                      color: BioTheme.limeSoft,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              Container(
                height: 27,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.025),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color.fromRGBO(225, 238, 228, 0.10),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(BioIcons.leaf, size: 12, color: BioTheme.limeSoft),
                    const SizedBox(width: 5),
                    const Text(
                      'BIOJAVERIANA',
                      style: TextStyle(
                        color: BioTheme.limeSoft,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Expanded(child: _Viewfinder(active: active)),
          SizedBox(
            height: 92,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 38),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SideButton(icon: BioIcons.imageOutline),
                  _CaptureButton(onTap: onCapture),
                  _SideButton(icon: BioIcons.flashOutline),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -4),
            child: const Text(
              'Toca el botón para identificar',
              style: TextStyle(color: BioTheme.textMuted, fontSize: 8.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    const focus = Color.fromRGBO(218, 230, 119, 0.38);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(0, 20, 17, 0.19),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color.fromRGBO(225, 238, 228, 0.08),
            width: 0.8,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(top: 18, left: 18, child: _Corner(Alignment.topLeft)),
            const Positioned(
              top: 18,
              right: 18,
              child: _Corner(Alignment.topRight),
            ),
            const Positioned(
              bottom: 18,
              left: 18,
              child: _Corner(Alignment.bottomLeft),
            ),
            const Positioned(
              bottom: 18,
              right: 18,
              child: _Corner(Alignment.bottomRight),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromRGBO(210, 227, 112, 0.07),
                    border: Border.all(
                      color: const Color.fromRGBO(218, 230, 119, 0.19),
                    ),
                  ),
                  child: Icon(
                    active ? BioIcons.camera : BioIcons.cameraOutline,
                    size: 31,
                    color: BioTheme.lime,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  active ? 'Cámara preparada' : 'Encuadra una especie',
                  style: const TextStyle(
                    color: BioTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  active
                      ? 'Ubica la especie en el centro del marco.'
                      : 'Animales, plantas y árboles',
                  style: const TextStyle(
                    color: BioTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            if (active) ...[
              const SizedBox(
                width: 32,
                height: 1,
                child: ColoredBox(color: focus),
              ),
              const SizedBox(
                width: 1,
                height: 32,
                child: ColoredBox(color: focus),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner(this.corner);

  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(
      color: Color.fromRGBO(218, 230, 119, 0.72),
      width: 2,
    );
    const radius = Radius.circular(10);
    final top = corner.y < 0;
    final left = corner.x < 0;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? radius : Radius.zero,
          topRight: top && !left ? radius : Radius.zero,
          bottomLeft: !top && left ? radius : Radius.zero,
          bottomRight: !top && !left ? radius : Radius.zero,
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: () {},
      child: DeepFrostGlass(
        width: 48,
        height: 48,
        borderRadius: 20,
        child: Center(
          child: Icon(icon, size: 22, color: BioTheme.lime),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioPressable(
      onTap: onTap,
      pressedOpacity: 0.82,
      pressedScale: 0.94,
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color.fromRGBO(225, 238, 151, 0.40),
            width: 1.5,
          ),
        ),
        child: Container(
          width: 65,
          height: 65,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(218, 230, 119, 0.12),
          ),
          child: Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: BioTheme.lime,
            ),
            child: Icon(
              BioIcons.camera,
              size: 26,
              color: BioTheme.backgroundDeep,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SoftFrostGlass(
      borderRadius: 27,
      height: 137,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GlassIcon(icon: icon, size: 41, iconSize: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: BioTextStyles.cardTitle.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  color: BioTheme.textMuted,
                  fontSize: 8.5,
                  height: 11 / 8.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
