class SoftwareMember {
  final String id;
  final String username;
  final String email;
  final String role;
  final int user;

  SoftwareMember({
    required this.id,
    required this.username,
    this.email = '',
    this.role = 'viewer',
    this.user = 0,
  });

  factory SoftwareMember.fromJson(Map<String, dynamic> json) => SoftwareMember(
        id: '${json['id']}',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? 'viewer',
        user: json['user'] as int? ?? 0,
      );
}
