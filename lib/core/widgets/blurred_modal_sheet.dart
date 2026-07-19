import 'dart:ui';

import 'package:flutter/material.dart';

/// Feuille modale plein écran (quasi) qui monte depuis le bas avec un fond
/// qui se floute et s'assombrit progressivement — jamais une nouvelle page,
/// jamais un simple `showModalBottomSheet` opaque. Utilisée pour la feuille
/// de filtres (voir `filters_sheet.dart`).
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
      return AnimatedBuilder(
        animation: curved,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10 * curved.value,
                    sigmaY: 10 * curved.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3 * curved.value),
                  ),
                ),
              ),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            ],
          );
        },
      );
    },
  );
}
