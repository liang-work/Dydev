/// User profile model returned from the accounts API.
class User {
  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final String bio;
  final String email;
  final String phone;
  final String dateJoined;
  final String lastLogin;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    this.nickname = '',
    this.avatar = '',
    this.bio = '',
    this.email = '',
    this.phone = '',
    this.dateJoined = '',
    this.lastLogin = '',
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: json['avatar'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      dateJoined: json['date_joined'] as String? ?? '',
      lastLogin: json['last_login'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'bio': bio,
        'email': email,
        'phone': phone,
        'date_joined': dateJoined,
        'last_login': lastLogin,
        'is_active': isActive,
      };
}
