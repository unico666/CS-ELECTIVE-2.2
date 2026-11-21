class AppProfile {
  const AppProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final String? fullName;
  final String role;

  bool get isAdmin => role == 'admin';

  factory AppProfile.fromMap(Map<String, dynamic> map) {
    final roleMap = map['roles'] as Map?;
    return AppProfile(
      id: map['id'] as String,
      email: (map['email'] as String?) ?? '',
      fullName: map['full_name'] as String?,
      role: (roleMap?['name'] as String?) ?? 'customer',
    );
  }
}
