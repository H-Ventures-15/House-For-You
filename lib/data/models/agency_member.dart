/// Rôle d'un utilisateur *au sein* d'une agence donnée — distinct du rôle
/// global [UserRole]. Permet plusieurs agents par agence avec des droits
/// différents (voir architecture-mvp.md, section 5).
enum AgencyMemberRole { owner, agent }

enum AgencyMemberStatus { pending, active, suspended }

class AgencyMember {
  const AgencyMember({
    required this.agencyId,
    required this.userId,
    required this.role,
    required this.status,
    required this.createdAt,
  });

  final String agencyId;
  final String userId;
  final AgencyMemberRole role;
  final AgencyMemberStatus status;
  final DateTime createdAt;

  factory AgencyMember.fromJson(Map<String, dynamic> json) {
    return AgencyMember(
      agencyId: json['agency_id'] as String,
      userId: json['user_id'] as String,
      role: AgencyMemberRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => AgencyMemberRole.agent,
      ),
      status: AgencyMemberStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => AgencyMemberStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'agency_id': agencyId,
        'user_id': userId,
        'role': role.name,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}
