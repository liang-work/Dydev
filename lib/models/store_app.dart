/// Status of a store app listing.
enum AppStatus {
  draft,
  pending,
  published,
  rejected,
  removed;

  String get label {
    switch (this) {
      case AppStatus.draft:
        return '草稿';
      case AppStatus.pending:
        return '审核中';
      case AppStatus.published:
        return '已上架';
      case AppStatus.rejected:
        return '已拒绝';
      case AppStatus.removed:
        return '已下架';
    }
  }

  /// Construct from the API string value.
  static AppStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return AppStatus.draft;
      case 'pending':
        return AppStatus.pending;
      case 'published':
        return AppStatus.published;
      case 'rejected':
        return AppStatus.rejected;
      case 'removed':
        return AppStatus.removed;
      default:
        return AppStatus.draft;
    }
  }
}

/// A store app listing returned from the store API.
class StoreApp {
  final int id;
  final String name;
  final String slug;
  final String iconUrl;
  final String coverUrl;
  final List<String> screenshots;
  final String currentVersion;
  final int versionCode;
  final AppStatus status;
  final int downloadCount;
  final int viewCount;
  final double ratingAverage;
  final int ratingCount;
  final int reviewCount;
  final String shortDescription;
  final String description;
  final String subtitle;
  final String websiteUrl;
  final String sourceUrl;
  final String downloadUrl;
  final String developerName;
  final String developerEmail;
  final String developerQq;
  final String developerWechat;
  final String developerContactCustom;
  final String supportUrl;
  final double price;
  final bool isFree;
  final List<String> tags;
  final List<String> platforms;
  final int fileSize;
  final bool useDistribute;
  final String? software;
  final String? channel;
  final String createdAt;
  final String updatedAt;

  StoreApp({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl = '',
    this.coverUrl = '',
    this.screenshots = const [],
    this.currentVersion = '',
    this.versionCode = 0,
    this.status = AppStatus.draft,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.shortDescription = '',
    this.description = '',
    this.subtitle = '',
    this.websiteUrl = '',
    this.sourceUrl = '',
    this.downloadUrl = '',
    this.developerName = '',
    this.developerEmail = '',
    this.developerQq = '',
    this.developerWechat = '',
    this.developerContactCustom = '',
    this.supportUrl = '',
    this.price = 0,
    this.isFree = true,
    this.tags = const [],
    this.platforms = const [],
    this.fileSize = 0,
    this.useDistribute = false,
    this.software,
    this.channel,
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory StoreApp.fromJson(Map<String, dynamic> json) {
    return StoreApp(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      screenshots: (json['screenshots'] as List<dynamic>?)
              ?.map((e) => e is Map ? (e['image_url'] as String? ?? '') : (e as String))
              .toList() ??
          [],
      currentVersion: json['current_version'] ?? '',
      versionCode: json['version_code'] as int? ?? 0,
      status: AppStatus.fromString(json['status'] ?? 'draft'),
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      ratingAverage: (json['rating_average'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      subtitle: json['subtitle'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      developerName: json['developer_name'] ?? '',
      developerEmail: json['developer_email'] ?? '',
      developerQq: json['developer_qq'] ?? '',
      developerWechat: json['developer_wechat'] ?? '',
      developerContactCustom: json['developer_contact_custom'] ?? '',
      supportUrl: json['support_url'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      isFree: json['is_free'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      platforms: (json['platforms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      fileSize: json['file_size'] as int? ?? 0,
      useDistribute: json['use_distribute'] as bool? ?? false,
      software: json['software'] as String?,
      channel: json['channel'] as String?,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon_url': iconUrl,
        'cover_url': coverUrl,
        'screenshots': screenshots,
        'current_version': currentVersion,
        'version_code': versionCode,
        'status': status.name,
        'short_description': shortDescription,
        'description': description,
        'subtitle': subtitle,
        'website_url': websiteUrl,
        'source_url': sourceUrl,
        'download_url': downloadUrl,
        'developer_name': developerName,
        'developer_email': developerEmail,
        'developer_qq': developerQq,
        'developer_wechat': developerWechat,
        'developer_contact_custom': developerContactCustom,
        'support_url': supportUrl,
        'price': price,
        'is_free': isFree,
        'tags': tags,
        'platforms': platforms,
        'file_size': fileSize,
        'use_distribute': useDistribute,
        'software': software,
        'channel': channel,
      };
}
