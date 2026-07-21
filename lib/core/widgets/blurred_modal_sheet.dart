import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Feuille modale plein écran (quasi) qui monte depuis le bas avec un fond
/// qui se floute et s'assombrit progressivement — jamais une nouvelle page,
/// jamais un simple `showModalBottomSheet` opaque. Utilisée pour la feuille
/// de filtres (voir `filters_sheet.dart`).
///
/// Fermable par swipe vers le bas depuis n'importe quelle zone du contenu,
/// pas seulement la croix — voir `_DismissibleSheet` : le geste suit le
/// doigt en direct, le fond s'éclaircit progressivement pendant le geste, et
/// il ne l'emporte sur le scroll interne que lorsque celui-ci est déjà
/// revenu en haut (voir UX_RULES.md section 9).
Future<T?> showBlurredModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  double heightFactor = 0.94,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fermer',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          // `showGeneralDialog` ne fournit pas d'ancêtre `Material` — requis
          // par `TextField`/`InkWell` à l'intérieur de la feuille.
          child: Material(
            type: MaterialType.transparency,
            child: Builder(builder: builder),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return _DismissibleSheet(routeAnimation: curved, child: child);
    },
  );
}

/// Combine la transition d'ouverture/fermeture de la route (fondu + flou du
/// fond, glissement du contenu) avec un geste de fermeture interactif par
/// swipe vers le bas, à la manière d'une vraie bottom sheet iOS/Apple Maps.
///
/// Le geste suit le doigt en direct : un swipe suffisamment long ou rapide
/// ferme la feuille avec une inertie de ressort qui prolonge la vitesse de
/// relâchement, un swipe incomplet la ramène de la même façon (voir
/// DECISIONS.md ADR-025 pour l'analyse du problème de fluidité corrigé
/// ici). Le scroll interne du contenu (`ListView` de `FiltersSheet`) reste
/// toujours prioritaire — la fermeture ne se déclenche que lorsque ce
/// scroll est déjà revenu en haut, détecté via les notifications de scroll
/// qui remontent naturellement la pile de widgets sans qu'un
/// `GestureDetector` concurrent n'ait besoin d'arbitrer avec l'arène de
/// gestes (même principe d'indépendance d'axes que UX_RULES.md section 4,
/// appliqué ici à un seul axe partagé entre scroll et geste de fermeture).
class _DismissibleSheet extends StatefulWidget {
  const _DismissibleSheet({required this.routeAnimation, required this.child});

  final Animation<double> routeAnimation;
  final Widget child;

  @override
  State<_DismissibleSheet> createState() => _DismissibleSheetState();
}

class _DismissibleSheetState extends State<_DismissibleSheet>
    with SingleTickerProviderStateMixin {
  /// Fraction de la hauteur de la feuille à partir de laquelle un
  /// relâchement confirme la fermeture — volontairement plus permissif que
  /// le seuil de la fiche détail (32 %, voir ADR-004) : une bottom sheet se
  /// ferme naturellement d'un petit geste, contrairement à la fiche qui
  /// occupe tout l'écran et mérite un geste plus délibéré.
  static const double _dismissThreshold = 0.18;

  /// Vitesse de relâchement (px/s) qui confirme la fermeture même sous le
  /// seuil de distance — un swipe rapide et court doit fermer tout autant
  /// qu'un swipe lent et long.
  static const double _dismissVelocity = 500;

  /// Même ressort que `SnappyPageScrollPhysics` (critique, sans rebond) —
  /// cohérence de sensation avec le reste de l'app. Contrairement à un
  /// `Tween`/`Curve` à durée fixe, un `SpringSimulation` part de la vitesse
  /// réelle de relâchement : l'inertie du geste se prolonge naturellement
  /// dans l'animation, qu'elle confirme la fermeture ou qu'elle y renonce.
  static final SpringDescription _spring =
      SpringDescription.withDampingRatio(mass: 0.3, stiffness: 180, ratio: 1);

  /// Position de glissement en pixels — `AnimationController.unbounded` :
  /// sert à la fois de valeur suivie 1:1 pendant le drag actif (`.value =`,
  /// ce qui interrompt net toute simulation en cours) et de simulation à
  /// ressort au relâchement (`animateWith`). Piloter tout depuis ce seul
  /// contrôleur — plutôt qu'un `setState` de champ brut — permet de
  /// ne reconstruire que le sous-arbre qui en dépend réellement (voir
  /// `build`), jamais le flou de fond.
  late final AnimationController _dragController;
  bool _hapticFired = false;

  /// Ignore les franchissements de seuil pendant la simulation de
  /// relâchement (`_settleDrag`) — seul le geste actif doit vibrer, pas la
  /// traversée mécanique du seuil par le ressort une fois le sort de la
  /// feuille déjà déterminé.
  bool _settling = false;
  double _sheetHeight = 1;

  double get _dragExtent => _dragController.value;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController.unbounded(vsync: this)
      ..addListener(_maybeFireHaptic);
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  void _accumulateRawDelta(double delta) {
    if (delta <= 0) return;
    if (_dragExtent == 0) {
      FocusScope.of(context).unfocus();
    }
    _settling = false;
    // Assignation directe : suit le doigt au pixel près, sans transiter par
    // une animation (et arrête net toute simulation de ressort en cours si
    // l'utilisateur reprend le geste avant qu'elle ne se termine).
    _dragController.value =
        (_dragExtent + delta).clamp(0.0, _sheetHeight * 1.5);
  }

  void _maybeFireHaptic() {
    if (_settling) return;
    final crossed = _dragExtent >= _sheetHeight * _dismissThreshold;
    if (crossed && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.lightImpact();
    } else if (!crossed && _hapticFired) {
      _hapticFired = false;
    }
  }

  void _settleDrag({double velocity = 0}) {
    if (_dragExtent == 0) return;
    final distanceFraction = _dragExtent / _sheetHeight;
    final shouldDismiss =
        distanceFraction >= _dismissThreshold || velocity >= _dismissVelocity;
    _hapticFired = false;
    _settling = true;
    final target = shouldDismiss ? _sheetHeight : 0.0;
    _dragController
        .animateWith(
      SpringSimulation(_spring, _dragExtent, target, velocity),
    )
        .whenComplete(() {
      _settling = false;
      if (shouldDismiss && mounted) Navigator.of(context).maybePop();
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // Seul le scrollable de premier niveau du contenu de la feuille pilote
    // la fermeture — un scrollable imbriqué plus profond (ex. une liste
    // horizontale) ne doit jamais déclencher ce comportement.
    if (notification.depth != 0) return false;

    if (notification is ScrollUpdateNotification) {
      final atTop =
          notification.metrics.pixels <= notification.metrics.minScrollExtent;
      final dragDelta = notification.dragDetails?.delta.dy;
      if (atTop && dragDelta != null && dragDelta > 0) {
        // Le contenu est déjà en haut : le geste vers le bas prend
        // immédiatement le contrôle, au pixel près (voir
        // `_accumulateRawDelta`) — jamais le delta amorti de
        // `ScrollMetrics.pixels` (voir DECISIONS.md ADR-024).
        _accumulateRawDelta(dragDelta);
      } else if (_dragExtent > 0 && !atTop && !_settling) {
        // Le scroll interne reprend la priorité (l'utilisateur a relâché
        // puis repris son scroll normal) : on relâche la feuille.
        _settleDrag();
      }
    } else if (notification is OverscrollNotification) {
      // `ClampingScrollPhysics` (Android) : passe par `OverscrollNotification`
      // plutôt qu'un `pixels` négatif. `dragDetails` reste le delta brut du
      // doigt quand disponible (drag actif) ; à défaut (fin de fling), on
      // retombe sur `overscroll` (delta déjà incrémental de son côté).
      final dragDelta = notification.dragDetails?.delta.dy;
      if (dragDelta != null && dragDelta > 0) {
        _accumulateRawDelta(dragDelta);
      } else if (notification.overscroll < 0) {
        _accumulateRawDelta(-notification.overscroll);
      }
    } else if (notification is ScrollEndNotification &&
        _dragExtent > 0 &&
        !_settling) {
      // `dragDetails` d'un `ScrollEndNotification` est un `DragEndDetails`
      // qui porte la vitesse réelle de relâchement — indispensable pour
      // que le ressort parte de la bonne inertie (voir `_settleDrag`).
      final velocity =
          notification.dragDetails?.velocity.pixelsPerSecond.dy ?? 0;
      _settleDrag(velocity: velocity);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _sheetHeight = constraints.maxHeight;
        return Stack(
          children: [
            // Flou de fond — reconstruit uniquement quand `routeAnimation`
            // tique, c'est-à-dire pendant la transition d'ouverture/
            // fermeture de la route (quelques centaines de ms), jamais
            // pendant un drag actif qui peut durer indéfiniment.
            // `BackdropFilter` est l'un des effets les plus coûteux de
            // Flutter (re-échantillonne et flou tout ce qu'il y a dessous à
            // chaque frame) : le recalculer à chaque pixel de glissement du
            // doigt provoquait les saccades observées sur iPhone (voir
            // DECISIONS.md ADR-025). Séparé du reste : ni le drag ni le
            // ressort de relâchement ne le déclenchent jamais.
            AnimatedBuilder(
              animation: widget.routeAnimation,
              builder: (context, _) {
                final blur = 10 * widget.routeAnimation.value;
                return Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                      child: const SizedBox.expand(),
                    ),
                  ),
                );
              },
            ),
            // Assombrissement du fond — lui reste continu pendant le drag
            // (un simple fondu alpha, coût négligeable comparé au flou), ce
            // qui donne la sensation d'un fond « qui se révèle
            // progressivement » sans jamais rejouer l'effet coûteux.
            AnimatedBuilder(
              animation:
                  Listenable.merge([widget.routeAnimation, _dragController]),
              builder: (context, _) {
                final dragProgress =
                    (_dragExtent / _sheetHeight).clamp(0.0, 1.0);
                final scrimOpacity =
                    0.3 * widget.routeAnimation.value * (1 - dragProgress);
                return Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: scrimOpacity),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation:
                  Listenable.merge([widget.routeAnimation, _dragController]),
              builder: (context, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(widget.routeAnimation),
                  child: Transform.translate(
                    offset: Offset(0, _dragExtent),
                    child: child,
                  ),
                );
              },
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
