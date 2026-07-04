class GitHubAccount {
  final String githubLogin;
  final String? githubName;
  final String? githubAvatar;
  final String createdAt;

  GitHubAccount({
    required this.githubLogin,
    this.githubName,
    this.githubAvatar,
    this.createdAt = '',
  });

  factory GitHubAccount.fromJson(Map<String, dynamic> json) => GitHubAccount(
        githubLogin: json['github_login'] as String? ?? '',
        githubName: json['github_name'] as String?,
        githubAvatar: json['github_avatar'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class GitHubMirror {
  final String id;
  final String name;
  final String baseUrl;
  final bool isActive;
  final int priority;

  GitHubMirror({
    required this.id,
    required this.name,
    required this.baseUrl,
    this.isActive = true,
    this.priority = 0,
  });

  factory GitHubMirror.fromJson(Map<String, dynamic> json) => GitHubMirror(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        baseUrl: json['base_url'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        priority: json['priority'] as int? ?? 0,
      );
}
