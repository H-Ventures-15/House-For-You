import 'property_feature.dart';
import 'property_media.dart';

enum TransactionType { sale, rent }

enum PropertyType { house, apartment, land, other }

enum PropertyStatus { draft, published, archived }

/// Précision de localisation publique choisie par l'agence — l'adresse
/// exacte, elle, ne vit jamais ici (voir [PropertyPrivateLocation]).
enum LocationPrecision { exact, approximate, cityOnly }

/// Modèle public d'un bien immobilier — ne contient QUE des données
/// publiables. L'adresse complète et les coordonnées exactes vivent dans une
/// table/modèle séparés ([PropertyPrivateLocation]).
class Property {
  const Property({
    required this.id,
    this.agentId,
    this.agencyId,
    required this.transactionType,
    required this.propertyType,
    required this.title,
    required this.description,
    required this.price,
    this.currency = 'EUR',
    required this.surface,
    this.landSurface,
    required this.bedrooms,
    this.bathrooms,
    this.garden = false,
    this.garage = false,
    this.terrace = false,
    this.energyScore,
    this.constructionYear,
    this.isExclusive = false,
    this.isFeatured = false,
    this.hasVirtualTour = false,
    this.previousPrice,
    required this.postalCode,
    required this.city,
    this.province,
    this.displayLatitude,
    this.displayLongitude,
    this.locationPrecision = LocationPrecision.approximate,
    required this.status,
    this.media = const [],
    this.features = const [],
    this.publishedAt,
    this.archivedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? agentId;
  final String? agencyId;
  final TransactionType transactionType;
  final PropertyType propertyType;

  // Résolus dans la locale courante (table property_translations côté BDD)
  final String title;
  final String description;

  final num price;
  final String currency;
  final num surface;
  final num? landSurface;
  final int bedrooms;
  final int? bathrooms;
  final bool garden;
  final bool garage;
  final bool terrace;
  final String? energyScore;
  final int? constructionYear;

  /// Badges éditoriaux/commerciaux (voir `property_badge.dart`) — mock à
  /// cette étape, `previousPrice` sert uniquement à dériver le badge "Prix
  /// réduit" (jamais affiché tel quel).
  final bool isExclusive;
  final bool isFeatured;
  final bool hasVirtualTour;
  final num? previousPrice;

  final String postalCode;
  final String city;
  final String? province;
  final double? displayLatitude;
  final double? displayLongitude;
  final LocationPrecision locationPrecision;

  final PropertyStatus status;
  final List<PropertyMedia> media;
  final List<PropertyFeature> features;

  final DateTime? publishedAt;
  final DateTime? archivedAt;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get coverPhotoUrl {
    if (media.isEmpty) return null;
    final cover = media.where((m) => m.isCover).toList();
    final chosen = cover.isNotEmpty ? cover.first : media.first;
    return chosen.thumbnailUrl ?? chosen.storagePath;
  }

  bool get isPublished =>
      status == PropertyStatus.published && deletedAt == null;

  factory Property.fromJson(
    Map<String, dynamic> json, {
    List<PropertyMedia> media = const [],
    List<PropertyFeature> features = const [],
    String? title,
    String? description,
  }) {
    return Property(
      id: json['id'] as String,
      agentId: json['agent_id'] as String?,
      agencyId: json['agency_id'] as String?,
      transactionType: TransactionType.values.firstWhere(
        (t) => t.name == json['transaction_type'],
        orElse: () => TransactionType.sale,
      ),
      propertyType: PropertyType.values.firstWhere(
        (t) => t.name == json['property_type'],
        orElse: () => PropertyType.other,
      ),
      title: title ?? json['title'] as String? ?? '',
      description: description ?? json['description'] as String? ?? '',
      price: json['price'] as num,
      currency: json['currency'] as String? ?? 'EUR',
      surface: json['surface'] as num,
      landSurface: json['land_surface'] as num?,
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int?,
      garden: json['garden'] as bool? ?? false,
      garage: json['garage'] as bool? ?? false,
      terrace: json['terrace'] as bool? ?? false,
      energyScore: json['energy_score'] as String?,
      constructionYear: json['construction_year'] as int?,
      isExclusive: json['is_exclusive'] as bool? ?? false,
      isFeatured: json['is_featured'] as bool? ?? false,
      hasVirtualTour: json['has_virtual_tour'] as bool? ?? false,
      previousPrice: json['previous_price'] as num?,
      postalCode: json['postal_code'] as String,
      city: json['city'] as String,
      province: json['province'] as String?,
      displayLatitude: (json['display_latitude'] as num?)?.toDouble(),
      displayLongitude: (json['display_longitude'] as num?)?.toDouble(),
      locationPrecision: LocationPrecision.values.firstWhere(
        (p) => p.name == json['location_precision'],
        orElse: () => LocationPrecision.approximate,
      ),
      status: PropertyStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PropertyStatus.draft,
      ),
      media: media,
      features: features,
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'] as String)
          : null,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'agent_id': agentId,
        'agency_id': agencyId,
        'transaction_type': transactionType.name,
        'property_type': propertyType.name,
        'price': price,
        'currency': currency,
        'surface': surface,
        'land_surface': landSurface,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'garden': garden,
        'garage': garage,
        'terrace': terrace,
        'energy_score': energyScore,
        'construction_year': constructionYear,
        'is_exclusive': isExclusive,
        'is_featured': isFeatured,
        'has_virtual_tour': hasVirtualTour,
        'previous_price': previousPrice,
        'postal_code': postalCode,
        'city': city,
        'province': province,
        'display_latitude': displayLatitude,
        'display_longitude': displayLongitude,
        'location_precision': locationPrecision.name,
        'status': status.name,
        'published_at': publishedAt?.toIso8601String(),
        'archived_at': archivedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Property copyWith({
    PropertyStatus? status,
    List<PropertyMedia>? media,
    List<PropertyFeature>? features,
  }) {
    return Property(
      id: id,
      agentId: agentId,
      agencyId: agencyId,
      transactionType: transactionType,
      propertyType: propertyType,
      title: title,
      description: description,
      price: price,
      currency: currency,
      surface: surface,
      landSurface: landSurface,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      garden: garden,
      garage: garage,
      terrace: terrace,
      energyScore: energyScore,
      constructionYear: constructionYear,
      isExclusive: isExclusive,
      isFeatured: isFeatured,
      hasVirtualTour: hasVirtualTour,
      previousPrice: previousPrice,
      postalCode: postalCode,
      city: city,
      province: province,
      displayLatitude: displayLatitude,
      displayLongitude: displayLongitude,
      locationPrecision: locationPrecision,
      status: status ?? this.status,
      media: media ?? this.media,
      features: features ?? this.features,
      publishedAt: publishedAt,
      archivedAt: archivedAt,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
