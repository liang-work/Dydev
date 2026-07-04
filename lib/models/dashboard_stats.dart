/// Dashboard statistics from the store stats API.
class DashboardStats {
  final int myAppCount;
  final int totalDownloads;
  final int reviewCount;
  final int platformAppCount;
  final int categoryCount;
  final int developerCount;

  DashboardStats({
    this.myAppCount = 0,
    this.totalDownloads = 0,
    this.reviewCount = 0,
    this.platformAppCount = 0,
    this.categoryCount = 0,
    this.developerCount = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      myAppCount: json['my_app_count'] ?? 0,
      totalDownloads: json['total_downloads'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      platformAppCount: json['app_count'] ?? 0,
      categoryCount: json['category_count'] ?? 0,
      developerCount: json['developer_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'my_app_count': myAppCount,
        'total_downloads': totalDownloads,
        'review_count': reviewCount,
        'app_count': platformAppCount,
        'category_count': categoryCount,
        'developer_count': developerCount,
      };
}
