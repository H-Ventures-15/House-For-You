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

/// Physique du feed vertical (Découvrir) uniquement — jamais les galeries
/// photo horizontales, qui restent volontairement aussi réactives qu'une
/// galerie classique (`SnappyPageScrollPhysics` seule).
///
/// Remplace la décision « change-t-on de page ? » de Flutter
/// (`PageScrollPhysics._getTargetPixels`), qui se contente de comparer la
/// vélocité à une tolérance quasi nulle (`ScrollPhysics.toleranceFor`, de
/// l'ordre de quelques pixels/seconde) : n'importe quel petit flick, même
/// sur quelques millimètres, change de page dès qu'il a la moindre vélocité
/// perceptible — c'est la cause du feed « trop nerveux » observé sur
/// iPhone (voir DECISIONS.md ADR-026). Un changement de bien exige ici une
/// intention nette : une distance parcourue suffisante, OU un swipe court
/// mais franchement rapide.
///
/// Nécessite `PageView(pageSnapping: false)` : `PageView` enveloppe sinon
/// systématiquement toute physique fournie dans sa propre `_kPagePhysics`
/// interne, qui déciderait alors seule du changement de page sans jamais
/// consulter `createBallisticSimulation` ci-dessous (voir DECISIONS.md
/// ADR-026 pour le détail de cette découverte).
class FeedPageScrollPhysics extends SnappyPageScrollPhysics {
  const FeedPageScrollPhysics({required this.currentPage, super.parent});

  /// Page actuellement installée (dernier bien réellement affiché) — fournie
  /// par le widget plutôt que devinée depuis la position fractionnaire
  /// courante. Un simple `page.round()` semble une estimation raisonnable de
  /// l'origine du geste, mais devient **incorrect** au-delà de 50 % de
  /// distance parcourue (il désigne alors la page cible, pas l'origine),
  /// inversant le sens du calcul de progression pour un swipe long et lent
  /// (vélocité quasi nulle au relâchement) — corrigé en connaissant la vraie
  /// origine plutôt qu'en la déduisant.
  final int Function() currentPage;

  /// Distance minimale (fraction de la hauteur d'une page) qui valide à
  /// elle seule un changement de bien, quelle que soit la vitesse — un
  /// drag lent et long reste une intention claire.
  static const double _distanceThreshold = 0.2;

  /// En dessous de cette distance, même une vitesse élevée ne suffit
  /// jamais — évite qu'un tremblement/tap involontaire avec un pic de
  /// vélocité minime ne soit interprété comme un swipe.
  static const double _minDistanceForFastFling = 0.05;

  /// Vitesse (px/s) à partir de laquelle un swipe court (mais au moins
  /// `_minDistanceForFastFling`) valide quand même le changement — « un
  /// swipe court mais vraiment rapide peut changer de bien ».
  static const double _fastFlingVelocity = 1200;

  @override
  FeedPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return FeedPageScrollPhysics(
      currentPage: currentPage,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // Hors limites (premier/dernier bien) : laisser le comportement par
    // défaut ramener dans les bornes de la liste.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final metrics = position as PageMetrics;
    final double page = metrics.page!;
    final double origin = currentPage().toDouble();
    final double progress =
        page - origin; // signé : + en avançant, - en reculant
    final double distanceFraction = progress.abs();

    final bool distanceIntentional = distanceFraction >= _distanceThreshold;
    final bool fastShortFling = velocity.abs() >= _fastFlingVelocity &&
        distanceFraction >= _minDistanceForFastFling;

    final double target;
    if (distanceFraction == 0) {
      target = origin;
    } else if (distanceIntentional || fastShortFling) {
      target = origin + (progress > 0 ? 1 : -1);
    } else {
      // Intention insuffisante : retour au bien courant, jamais un
      // changement sur un simple tremblement de la main.
      target = origin;
    }

    final double targetPixels = _pixelsForPage(metrics, target);
    if (targetPixels == position.pixels) return null;
    final tolerance = toleranceFor(position);
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      targetPixels,
      velocity,
      tolerance: tolerance,
    );
  }

  double _pixelsForPage(PageMetrics metrics, double page) {
    return page * (metrics.viewportDimension * metrics.viewportFraction);
  }
}
