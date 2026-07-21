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
  /// relâchement confirme la fermeture (32 % — même seuil que la fermeture
  /// de la fiche détail, voir ADR-004/UX_RULES.md section 8).
  static const double _dismissThreshold = 0.32;

  /// Vitesse de relâchement (px/s) qui confirme la fermeture même sous le
  /// seuil de distance — un swipe rapide et court doit fermer tout autant
  /// qu'un swipe lent et long.
  static const double _dismissVelocity = 800;

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

  void _accumulateOverscroll(double delta) {
    if (delta <= 0) return;
    _setDragExtent(_dragExtent + delta);
  }

  /// Fixe directement la distance de glissement — utilisé par le cas
  /// `BouncingScrollPhysics` (iOS, la cible principale de l'app) où
  /// `ScrollUpdateNotification.metrics.pixels` donne déjà une position
  /// absolue au-delà du haut, contrairement à `OverscrollNotification` qui ne
  /// fournit qu'un delta incrémental (voir cas `ClampingScrollPhysics`
  /// ci-dessous). Permet au geste de suivre le doigt dans les deux sens
  /// (tirer, puis relâcher partiellement sans lever le doigt).
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

    if (notification is OverscrollNotification) {
      // `ClampingScrollPhysics` (Android) : `overscroll` est un delta
      // incrémental, négatif quand on tire au-delà du haut de la liste (ce
      // qui correspond à un swipe vers le bas) — positif au-delà du bas,
      // ignoré ici.
      if (notification.overscroll < 0) {
        _accumulateOverscroll(-notification.overscroll);
      }
    } else if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      if (metrics.pixels < metrics.minScrollExtent) {
        // `BouncingScrollPhysics` (iOS, cible principale de l'app) : le
        // scroll dépasse directement la limite, `pixels` donne une position
        // absolue plutôt qu'un delta.
        _setDragExtent(metrics.minScrollExtent - metrics.pixels);
      } else if (_dragExtent > 0) {
        // Le scroll interne reprend la priorité : on relâche la feuille.
        _settleDrag();
      }
    } else if (notification is ScrollEndNotification && _dragExtent > 0) {
      _settleDrag();
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
