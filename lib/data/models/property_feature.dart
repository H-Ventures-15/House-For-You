/// Critère ad hoc / plus rarement filtré (les critères fréquents — salles de
/// bain, surface du terrain, jardin, garage, terrasse, PEB, année de
/// construction — sont des colonnes structurées directement sur [Property]).
class PropertyFeature {
  const PropertyFeature({
    required this.id,
    required this.propertyId,
    required this.featureKey,
    required this.featureValue,
  });

  final String id;
  final String propertyId;
  final String featureKey;
  final String featureValue;

  factory PropertyFeature.fromJson(Map<String, dynamic> json) {
    return PropertyFeature(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      featureKey: json['feature_key'] as String,
      featureValue: json['feature_value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'feature_key': featureKey,
        'feature_value': featureValue,
      };
}
