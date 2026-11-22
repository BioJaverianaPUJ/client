import 'package:flutter_test/flutter_test.dart';
import 'package:biojaveriana/widgets/level_badge.dart';

void main() {
  test('RF-36: veinte insignias distintas y la del 20 se conserva', () {
    final names = {for (var l = 1; l <= 20; l++) badgeName(l)};
    expect(names.length, 20);
    expect(badgeName(1), 'Semilla I');
    expect(badgeName(20), 'Bosque IV');
    expect(badgeLevel(27), 20);
    expect(badgeName(27), badgeName(20));
    expect(badgeLevel(0), 1);
  });
}
