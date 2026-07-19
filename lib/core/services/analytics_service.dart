import 'package:flutter/foundation.dart';
import '../../data/models/property_event.dart';

/// Interface transversale de tracking — appelée depuis les providers de
/// chaque feature pour éviter de dupliquer la logique d'événements dans
/// chaque écran (voir architecture-mvp.md, section 1).
///
/// Côté Supabase (étape 9 du plan), l'implémentation réelle n'insère jamais
/// directement dans `property_events` : elle appelle l'Edge Function
/// `track-event` qui valide, limite le débit et rejette les événements
/// incohérents avant écriture (voir architecture-mvp.md, section 5).
abstract class AnalyticsService {
  Future<void> track(PropertyEvent event);
}

/// Implémentation mock — logue localement, ne persiste rien.
class MockAnalyticsService implements AnalyticsService {
  @override
  Future<void> track(PropertyEvent event) async {
    if (kDebugMode) {
      debugPrint(
        '[MockAnalyticsService] ${event.eventType.name} → ${event.propertyId}',
      );
    }
  }
}
