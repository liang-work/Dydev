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
  final String currentVersion;
  final AppStatus status;
  final int downloadCount;
  final int viewCount;
  final double ratingAverage;
  final int ratingCount;
  final int reviewCount;
  final String shortDescription;
  final String createdAt;
  final String updatedAt;

  StoreApp({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl = '',
    this.currentVersion = '',
    this.status = AppStatus.draft,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.shortDescription = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory StoreApp.fromJson(Map<String, dynamic> json) {
    return StoreApp(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      currentVersion: json['current_version'] ?? '',
      status: AppStatus.fromString(json['status'] ?? 'draft'),
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      ratingAverage: (json['rating_average'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      shortDescription: json['short_description'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon_url': iconUrl,
        'current_version': currentVersion,
        'status': status.name,
        'download_count': downloadCount,
        'view_count': viewCount,
        'rating_average': ratingAverage,
        'rating_count': ratingCount,
        'review_count': reviewCount,
        'short_description': shortDescription,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
