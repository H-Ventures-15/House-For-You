/// Événement analytique léger. Côté Supabase, ce modèle n'est jamais inséré
/// directement par le client : il transite par l'Edge Function `track-event`
/// qui valide/limite le débit avant écriture (voir architecture-mvp.md,
/// section 5). Au MVP mock, le repository se contente de logguer localement.
enum PropertyEventType {
  feedImpression,
  detailOpen,
  favoriteAdd,
  favoriteRemove,
  share,
  contactRequest,
  visitRequest,
  viewDuration,
}

class PropertyEvent {
  const PropertyEvent({
    required this.propertyId,
    this.userId,
    required this.sessionId,
    required this.eventType,
    this.value,
    required this.createdAt,
  });

  final String propertyId;
  final String? userId;
  final String sessionId;
  final PropertyEventType eventType;

  /// Ex. durée de consultation en secondes pour `viewDuration`.
  final num? value;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'user_id': userId,
        'session_id': sessionId,
        'event_type': eventType.name,
        'value': value,
        'created_at': createdAt.toIso8601String(),
      };
}
