class Software {
  final String id;
  final String name;
  final String slug;
  final String description;
  final List<String> platforms;
  final String iconUrl;
  final String websiteUrl;
  final String token;
  final String? telemetryToken;
  final String? announcementToken;
  final String? updateToken;
  final int versionCount;
  final String role;
  final String? owner;
  final String createdAt;

  Software({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.platforms,
    this.iconUrl = '',
    this.websiteUrl = '',
    required this.token,
    this.telemetryToken,
    this.announcementToken,
    this.updateToken,
    this.versionCount = 0,
    this.role = 'viewer',
    this.owner,
    this.createdAt = '',
  });

  factory Software.fromJson(Map<String, dynamic> json) => Software(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String? ?? '',
        platforms: (json['platforms'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        iconUrl: json['icon_url'] as String? ?? '',
        websiteUrl: json['website_url'] as String? ?? '',
        token: json['token'] as String? ?? '',
        telemetryToken: json['telemetry_token'] as String?,
        announcementToken: json['announcement_token'] as String?,
        updateToken: json['update_token'] as String?,
        versionCount: json['version_count'] as int? ?? 0,
        role: json['role'] as String? ?? 'viewer',
        owner: json['owner']?.toString(),
        createdAt: json['created_at'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'description': description,
        'platforms': platforms,
        'icon_url': iconUrl,
        'website_url': websiteUrl,
      };
}
