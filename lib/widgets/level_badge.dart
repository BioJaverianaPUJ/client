import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/bio_theme.dart';

/// Etapas de crecimiento: cada una agrupa cuatro niveles (RF-36).
const _stages = <(String, IconData, Color, Color)>[
  ('Semilla', Icons.grain_rounded, Color(0xFFB9A27A), Color(0xFF5E4B32)),
  ('Brote', Icons.grass_rounded, Color(0xFF9CCB72), Color(0xFF2F5A2A)),
  ('Hoja', Icons.eco_rounded, Color(0xFFD4E27E), Color(0xFF3F6B2C)),
  ('Árbol', Icons.park_rounded, Color(0xFF7FD1B9), Color(0xFF1C5A4C)),
  ('Bosque', Icons.forest_rounded, Color(0xFFFFD36E), Color(0xFF6B4A12)),
];

/// Nivel visible de la insignia: del 1 al 20; desde el 20 se conserva la 20.
int badgeLevel(int level) => level.clamp(1, 20);

/// Nombre de la insignia, por ejemplo «Hoja III».
String badgeName(int level) {
  final l = badgeLevel(level);
  const roman = ['I', 'II', 'III', 'IV'];
  return '${_stages[(l - 1) ~/ 4].$1} ${roman[(l - 1) % 4]}';
}

/// Insignia única para cada nivel del 1 al 20: la etapa define el ícono y el
/// color, y el número de puntas del contorno crece dentro de cada etapa.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 56});
  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = badgeLevel(level);
    final (_, icon, light, dark) = _stages[(l - 1) ~/ 4];
    final step = (l - 1) % 4;
    return Semantics(
      label: 'Insignia ${badgeName(l)}, nivel $l',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BadgePainter(
            points: 5 + step * 2,
            light: light,
            dark: dark,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: BioTheme.backgroundDeep, size: size * 0.34),
                Text(
                  '$l',
                  style: TextStyle(
                    color: BioTheme.backgroundDeep,
                    fontSize: size * 0.2,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  _BadgePainter({required this.points, required this.light, required this.dark});
  final int points;
  final Color light, dark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.84;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, Color.lerp(light, dark, 0.45)!],
        ).createShader(Offset.zero & size),
    );
    canvas.drawCircle(
      center,
      outer * 0.66,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer * 0.06
        ..color = dark.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.points != points || old.light != light || old.dark != dark;
}
