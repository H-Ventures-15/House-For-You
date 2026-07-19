import 'package:flutter/material.dart';

/// Conteneur des branches d'un [StatefulShellRoute] avec un fondu enchaîné
/// entre onglets, au lieu du changement instantané par défaut d'IndexedStack.
///
/// Chaque branche reste montée en permanence (comme avec IndexedStack) pour
/// préserver son état de navigation — seule l'opacité change, et
/// [IgnorePointer]/[TickerMode] désactivent interactions et animations des
/// branches inactives.
class BranchFadeContainer extends StatelessWidget {
  const BranchFadeContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (int i = 0; i < children.length; i++)
          _AnimatedBranch(isActive: i == currentIndex, child: children[i]),
      ],
    );
  }
}

class _AnimatedBranch extends StatelessWidget {
  const _AnimatedBranch({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !isActive,
        child: TickerMode(
          enabled: isActive,
          child: AnimatedOpacity(
            opacity: isActive ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: child,
          ),
        ),
      ),
    );
  }
}
