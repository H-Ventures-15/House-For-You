class Agency {
  const Agency({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.address,
    this.postalCode,
    this.city,
    this.coverageArea,
    this.specialties = const [],
    this.phone,
    this.email,
    this.website,
    this.verified = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? postalCode;
  final String? city;
  final String? coverageArea;
  final List<String> specialties;
  final String? phone;
  final String? email;
  final String? website;
  final bool verified;
  final DateTime createdAt;

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      postalCode: json['postal_code'] as String?,
      city: json['city'] as String?,
      coverageArea: json['coverage_area'] as String?,
      specialties: (json['specialties'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      verified: json['verified'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'logo_url': logoUrl,
        'address': address,
        'postal_code': postalCode,
        'city': city,
        'coverage_area': coverageArea,
        'specialties': specialties,
        'phone': phone,
        'email': email,
        'website': website,
        'verified': verified,
        'created_at': createdAt.toIso8601String(),
      };
}
