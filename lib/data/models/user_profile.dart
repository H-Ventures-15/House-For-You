/// Rôle applicatif global de l'utilisateur (distinct du rôle au sein d'une
/// agence, voir [AgencyMember]).
enum UserRole { user, agent, admin }

UserRole userRoleFromString(String value) => UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.user,
    );

class UserProfile {
  const UserProfile({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final UserRole role;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Utilisateur' : parts.join(' ');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: userRoleFromString(json['role'] as String? ?? 'user'),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? avatarUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      role: role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
