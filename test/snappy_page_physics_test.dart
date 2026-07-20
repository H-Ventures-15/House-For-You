import 'package:flutter_test/flutter_test.dart';
import 'package:house_for_you/core/widgets/snappy_page_physics.dart';

void main() {
  test(
    'le ressort de SnappyPageScrollPhysics est plus raide que le défaut '
    'PageScrollPhysics (settle plus rapide, sans rebond)',
    () {
      const physics = SnappyPageScrollPhysics();
      final spring = physics.spring;

      // Défaut Flutter (ScrollPhysics._kDefaultSpring) : mass 0.5,
      // stiffness 100 — une masse plus faible et une raideur plus élevée
      // font converger la simulation plus vite vers la page cible.
      expect(spring.mass, lessThan(0.5));
      expect(spring.stiffness, greaterThan(100));
    },
  );

  test('SnappyPageScrollPhysics.applyTo conserve le type concret', () {
    const physics = SnappyPageScrollPhysics();
    final applied = physics.applyTo(null);
    expect(applied, isA<SnappyPageScrollPhysics>());
  });
}
