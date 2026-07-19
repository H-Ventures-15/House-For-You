enum LeadType { contact, visit }

enum LeadStatus { newLead, contacted, scheduled, closed }

/// Demande de contact ou de visite — enregistrée en base plutôt que de se
/// contenter d'ouvrir le téléphone/email de l'agence, pour pouvoir prouver
/// aux agences que l'app leur apporte des prospects (architecture-mvp.md v2).
class Lead {
  const Lead({
    required this.id,
    required this.propertyId,
    required this.agencyId,
    this.agentId,
    required this.userId,
    required this.type,
    this.message,
    required this.firstName,
    required this.phone,
    this.availabilitySlots = const [],
    required this.consent,
    this.status = LeadStatus.newLead,
    required this.createdAt,
  });

  final String id;
  final String propertyId;
  final String agencyId;
  final String? agentId;
  final String userId;
  final LeadType type;
  final String? message;
  final String firstName;
  final String phone;

  /// 2-3 disponibilités proposées pour une demande de visite (ISO 8601).
  final List<DateTime> availabilitySlots;
  final bool consent;
  final LeadStatus status;
  final DateTime createdAt;

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      propertyId: json['property_id'] as String,
      agencyId: json['agency_id'] as String,
      agentId: json['agent_id'] as String?,
      userId: json['user_id'] as String,
      type: LeadType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => LeadType.contact,
      ),
      message: json['message'] as String?,
      firstName: json['first_name'] as String,
      phone: json['phone'] as String,
      availabilitySlots: (json['availability_slots'] as List<dynamic>? ?? [])
          .map((e) => DateTime.parse(e as String))
          .toList(),
      consent: json['consent'] as bool? ?? false,
      status: LeadStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LeadStatus.newLead,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'agency_id': agencyId,
        'agent_id': agentId,
        'user_id': userId,
        'type': type.name,
        'message': message,
        'first_name': firstName,
        'phone': phone,
        'availability_slots':
            availabilitySlots.map((d) => d.toIso8601String()).toList(),
        'consent': consent,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}
