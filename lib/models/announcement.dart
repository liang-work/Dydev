class Announcement {
  final String id;
  final String announcementType;
  final String title;
  final String content;
  final String status;
  final String filterType;
  final List<String> filterVersions;
  final List<String> filterChannels;
  final String? publishedAt;
  final String? expiresAt;
  final String createdAt;

  Announcement({
    required this.id,
    this.announcementType = 'update',
    this.title = '',
    this.content = '',
    this.status = 'draft',
    this.filterType = 'all',
    this.filterVersions = const [],
    this.filterChannels = const [],
    this.publishedAt,
    this.expiresAt,
    this.createdAt = '',
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: '${json['id']}',
        announcementType: json['announcement_type'] as String? ?? 'update',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        filterType: json['filter_type'] as String? ?? 'all',
        filterVersions: (json['filter_versions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        filterChannels: (json['filter_channels'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        publishedAt: json['published_at'] as String?,
        expiresAt: json['expires_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );
}
