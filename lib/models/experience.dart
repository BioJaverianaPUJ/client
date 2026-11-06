import 'dart:math' as math;

/// RF-36: XP is authoritative server data; level is derived, never awarded here.
class Experience {
  Experience(this.xp) {
    if (xp < 0) throw ArgumentError.value(xp, 'xp');
  }
  final int xp;
  int get level {
    if (xp < 10) return 1;
    var result = 2;
    while (10 * math.pow(1.5, result - 1) <= xp) {
      result++;
    }
    return result;
  }

  int get nextThreshold => (10 * math.pow(1.5, level - 1)).ceil();
  int get currentThreshold =>
      level == 1 ? 0 : (10 * math.pow(1.5, level - 2)).ceil();
  double get fraction =>
      ((xp - currentThreshold) / (nextThreshold - currentThreshold)).clamp(
        0,
        1,
      );
}
