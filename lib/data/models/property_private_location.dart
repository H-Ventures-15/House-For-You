/// Localisation exacte d'un bien — table strictement séparée de [Property]
/// car une policy RLS protège des LIGNES, pas des colonnes. En isolant
/// l'adresse complète et les coordonnées exactes ici, une policy mal écrite
/// sur `properties` ne peut jamais les faire fuiter (voir architecture-mvp.md,
/// section 5). Chargé uniquement côté agent/agence via un repository séparé
/// — jamais inclus dans le modèle [Property] public.
class PropertyPrivateLocation {
  const PropertyPrivateLocation({
    required this.propertyId,
    required this.addressFull,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String propertyId;
  final String addressFull;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  factory PropertyPrivateLocation.fromJson(Map<String, dynamic> json) {
    return PropertyPrivateLocation(
      propertyId: json['property_id'] as String,
      addressFull: json['address_full'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'address_full': addressFull,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': updatedAt.toIso8601String(),
      };
}
