import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

/// Feuille modale plein écran (quasi) qui monte depuis le bas avec un fond
/// qui se floute et s'assombrit progressivement — jamais une nouvelle page,
/// jamais un simple `showModalBottomSheet` opaque. Utilisée pour la feuille
/// de filtres (voir `filters_sheet.dart`).
///
/// Fermable par swipe vers le bas depuis n'importe quelle zone du contenu,
/// pas seulement la croix — voir `_DismissibleSheet` : le geste suit le
/// doigt en direct, le fond se déflloute/s'éclaircit progressivement pendant
/// le geste, et il ne l'emporte sur le scroll interne que lorsque celui-ci
/// est déjà revenu en haut (voir UX_RULES.md section 9).
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
/// Le geste suit le doigt en direct (le fond se dé-floute/s'éclaircit
/// proportionnellement) : un swipe suffisamment long ou rapide ferme la
/// feuille, un swipe incomplet la ramène doucement en place. Le scroll
/// interne du contenu (`ListView` de `FiltersSheet`) reste toujours
/// prioritaire — la fermeture ne se déclenche que lorsque ce scroll est déjà
/// revenu en haut, détecté via les `OverscrollNotification`/`ScrollUpdate
/// Notification` qui remontent naturellement la pile de widgets sans qu'un
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

  late final AnimationController _snapController;

  /// Distance parcourue par le drag au moment où le relâchement déclenche le
  /// retour en place — sert de point de départ à `_snapController` pour
  /// interpoler `_dragExtent` jusqu'à 0.
  double _snapStart = 0;

  double _dragExtent = 0;
  bool _hapticFired = false;
  double _sheetHeight = 1;

  @override
  void initState() {
    super.initState();
    // Créé systématiquement à `initState` plutôt qu'en `late final` paresseux
    // : un `late` initialisé seulement au premier drag ne serait jamais créé
    // si l'utilisateur ferme la feuille sans jamais glisser, et sa création
    // tardive dans `dispose()` échoue (l'élément est déjà en cours de
    // désactivation, `TickerMode` n'est plus consultable).
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_onSnapTick);
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onSnapTick() {
    setState(() {
      _dragExtent =
          _snapStart * (1 - Curves.easeOut.transform(_snapController.value));
    });
  }

  /// Accumule un delta de glissement **brut** (celui du doigt, pas celui —
  /// amorti — que la physique de scroll choisit d'appliquer à sa propre
  /// liste). C'est le point clé : `BouncingScrollPhysics` (iOS, la cible
  /// principale de l'app) applique un fort amortissement type « élastique »
  /// à `ScrollMetrics.pixels` au-delà des bornes (rubber-banding délibéré,
  /// pensé pour un rebond de scroll, pas pour piloter un geste de
  /// fermeture) — un swipe de 200 px du doigt ne déplaçait `pixels` que de
  /// quelques dizaines de pixels, obligeant à un geste bien plus long que
  /// prévu pour atteindre le seuil de fermeture. En accumulant directement
  /// `DragUpdateDetails.delta` (fourni par `ScrollNotification.dragDetails`,
  /// non amorti), la feuille suit le doigt au pixel près, quelle que soit la
  /// physique de scroll de la plateforme.
  void _accumulateRawDelta(double delta) {
    if (delta <= 0) return;
    _setDragExtent(_dragExtent + delta);
  }

  void _setDragExtent(double value) {
    final clamped = value.clamp(0.0, double.infinity);
    if (clamped == _dragExtent) return;
    if (_dragExtent == 0 && clamped > 0) {
      FocusScope.of(context).unfocus();
    }
    _snapController.stop();
    setState(() => _dragExtent = clamped);
    _maybeFireHaptic();
  }

  void _maybeFireHaptic() {
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
    if (shouldDismiss) {
      Navigator.of(context).maybePop();
      return;
    }
    // Swipe incomplet : retour doux en place (voir UX_RULES.md section 10).
    _snapStart = _dragExtent;
    _snapController
      ..value = 0
      ..forward();
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
        // `_accumulateRawDelta`).
        _accumulateRawDelta(dragDelta);
      } else if (_dragExtent > 0 && !atTop) {
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
    } else if (notification is ScrollEndNotification && _dragExtent > 0) {
      // `dragDetails` d'un `ScrollEndNotification` est un `DragEndDetails`
      // qui porte la vitesse réelle de relâchement — indispensable pour
      // qu'un swipe rapide et court ferme la feuille (voir
      // `_dismissVelocity`), jamais exploité tant que ce champ n'est pas lu.
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
        return AnimatedBuilder(
          animation: widget.routeAnimation,
          builder: (context, child) {
            final routeValue = widget.routeAnimation.value;
            final dragProgress = (_dragExtent / _sheetHeight).clamp(0.0, 1.0);
            // Le fond se dé-floute/s'éclaircit progressivement pendant le
            // geste, pas seulement lors de la fermeture confirmée — jamais
            // de saut brutal entre "geste en cours" et "route qui se ferme".
            final backdropIntensity = routeValue * (1 - dragProgress);
            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10 * backdropIntensity,
                        sigmaY: 10 * backdropIntensity,
                      ),
                      child: Container(
                        color: Colors.black
                            .withValues(alpha: 0.3 * backdropIntensity),
                      ),
                    ),
                  ),
                ),
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(widget.routeAnimation),
                  child: Transform.translate(
                    offset: Offset(0, _dragExtent),
                    child: child,
                  ),
                ),
              ],
            );
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: widget.child,
          ),
        );
      },
    );
  }
}
