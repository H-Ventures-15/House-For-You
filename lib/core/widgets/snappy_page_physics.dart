import 'package:flutter/material.dart';

/// Physique de `PageView` avec un ressort de fin de geste plus raide que le
/// défaut Flutter (`mass: 0.5, stiffness: 100, ratio: 1.1`) — le suivi du
/// doigt pendant le drag est déjà 1:1 nativement (rien à améliorer là), mais
/// le settle qui suit le relâchement du doigt paraissait un peu mou. Une
/// masse plus faible et une raideur plus élevée réduisent le temps de
/// convergence sans provoquer de rebond (ratio ≥ 1), pour une sensation de
/// changement de page quasi instantanée façon TikTok/Instagram.
class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      SpringDescription.withDampingRatio(mass: 0.3, stiffness: 180, ratio: 1);
}
