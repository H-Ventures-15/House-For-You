import 'package:flutter/widgets.dart';

/// Réduction légère et retour élastique discret à l'appui — micro-animation
/// partagée par les actions principales (favori, partager, agence, filtre,
/// recherches sauvegardées, CTA des filtres). Utilise un simple [Listener]
/// (jamais un [GestureDetector]) pour observer les évènements de pointeur
/// sans jamais participer à l'arène de gestes ni intercepter le tap destiné
/// au widget enveloppé (bouton Material, `InkWell`...).
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.scale = 0.94,
    super.key,
  });

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
