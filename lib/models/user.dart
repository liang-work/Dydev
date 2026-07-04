/// User profile model returned from the accounts API.
class User {
  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final String bio;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.username,
    this.nickname = '',
    this.avatar = '',
    this.bio = '',
    this.email = '',
    this.phone = '',
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
      };
}
