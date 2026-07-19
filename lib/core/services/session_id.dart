import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Identifiant de session anonyme, généré une fois par lancement de l'app —
/// requis par `PropertyEvent.sessionId` (les invités génèrent aussi des
/// événements, voir architecture-mvp.md section 5).
final sessionIdProvider = Provider<String>((ref) {
  final random = Random();
  final suffix = List.generate(
    12,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '${DateTime.now().millisecondsSinceEpoch}-$suffix';
});
