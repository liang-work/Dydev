import 'store_app.dart';

/// Dashboard statistics computed from the developer's own app list.
///
/// All values are derived from the [StoreApp] list returned by
/// `/api/store/apps/my_apps/` — no separate stats endpoint is used.
class DashboardStats {
  /// Number of apps the developer has created (any status).
  final int myAppCount;

  /// Sum of [StoreApp.downloadCount] across all the developer's apps.
  final int totalDownloads;

  /// Sum of [StoreApp.reviewCount] across all the developer's apps.
  final int totalReviews;

  /// Number of the developer's apps with status == published (已上架).
  final int publishedAppCount;

  const DashboardStats({
    this.myAppCount = 0,
    this.totalDownloads = 0,
    this.totalReviews = 0,
    this.publishedAppCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'my_app_count': myAppCount,
        'total_downloads': totalDownloads,
        'total_reviews': totalReviews,
        'published_app_count': publishedAppCount,
      };

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      myAppCount: json['my_app_count'] ?? 0,
      totalDownloads: json['total_downloads'] ?? 0,
      totalReviews: json['total_reviews'] ?? 0,
      publishedAppCount: json['published_app_count'] ?? 0,
    );
  }

  /// Compute stats directly from a list of [StoreApp]s.
  factory DashboardStats.fromApps(List<StoreApp> apps) {
    int totalDownloads = 0;
    int totalReviews = 0;
    int publishedCount = 0;

    for (final app in apps) {
      totalDownloads += app.downloadCount;
      totalReviews += app.reviewCount;
      if (app.status == AppStatus.published) {
        publishedCount++;
      }
    }

    return DashboardStats(
      myAppCount: apps.length,
      totalDownloads: totalDownloads,
      totalReviews: totalReviews,
      publishedAppCount: publishedCount,
    );
  }
}
