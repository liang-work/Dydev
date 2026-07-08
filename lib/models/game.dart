import 'game_category.dart';
import 'game_version.dart';
import 'game_screenshot.dart';
import 'game_issue.dart';

class Game {
  final int id;
  final String name;
  final String slug;
  final String subtitle;
  final String shortDescription;
  final String description;
  final int? category;
  final String categoryName;
  final GameCategory? categoryDetail;
  final List<String> tags;
  final String developer;
  final String developerName;
  final String iconUrl;
  final String coverUrl;
  final List<String> platforms;
  final String priceType;
  final double price;
  final String donationUrl;
  final String giteaRepo;
  final String giteaRepoFullName;
  final String giteaRepoUrl;
  final String githubRepo;
  final String githubRepoFullName;
  final String githubRepoUrl;
  final String distributeSoftware;
  final int downloadCount;
  final int viewCount;
  final double ratingAverage;
  final int ratingCount;
  final int reviewCount;
  final String status;
  final List<String> badges;
  final String rejectionReason;
  final String websiteUrl;
  final String sourceUrl;
  final List<CustomLink> customLinks;
  final List<GameScreenshot> screenshots;
  final List<GameVersion> versions;
  final List<GameIssue> issues;
  final String shortCode;
  final String publishedAt;
  final String createdAt;
  final String updatedAt;

  Game({
    required this.id,
    required this.name,
    this.slug = '',
    this.subtitle = '',
    this.shortDescription = '',
    this.description = '',
    this.category,
    this.categoryName = '',
    this.categoryDetail,
    this.tags = const [],
    this.developer = '',
    this.developerName = '',
    this.iconUrl = '',
    this.coverUrl = '',
    this.platforms = const [],
    this.priceType = 'free',
    this.price = 0,
    this.donationUrl = '',
    this.giteaRepo = '',
    this.giteaRepoFullName = '',
    this.giteaRepoUrl = '',
    this.githubRepo = '',
    this.githubRepoFullName = '',
    this.githubRepoUrl = '',
    this.distributeSoftware = '',
    this.downloadCount = 0,
    this.viewCount = 0,
    this.ratingAverage = 0.0,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.status = 'draft',
    this.badges = const [],
    this.rejectionReason = '',
    this.websiteUrl = '',
    this.sourceUrl = '',
    this.customLinks = const [],
    this.screenshots = const [],
    this.versions = const [],
    this.issues = const [],
    this.shortCode = '',
    this.publishedAt = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      subtitle: json['subtitle'] ?? '',
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] as int?,
      categoryName: json['category_name'] ?? '',
      categoryDetail: json['category_detail'] != null
          ? GameCategory.fromJson(json['category_detail'])
          : null,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      developer: json['developer'] ?? '',
      developerName: json['developer_name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      platforms: (json['platforms'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      priceType: json['price_type'] ?? 'free',
      price: (json['price'] ?? 0).toDouble(),
      donationUrl: json['donation_url'] ?? '',
      giteaRepo: json['gitea_repo'] ?? '',
      giteaRepoFullName: json['gitea_repo_full_name'] ?? '',
      giteaRepoUrl: json['gitea_repo_url'] ?? '',
      githubRepo: json['github_repo'] ?? '',
      githubRepoFullName: json['github_repo_full_name'] ?? '',
      githubRepoUrl: json['github_repo_url'] ?? '',
      distributeSoftware: json['distribute_software'] ?? '',
      downloadCount: json['download_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      ratingAverage: (json['rating_average'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      reviewCount: json['review_count'] ?? 0,
      status: json['status'] ?? 'draft',
      badges: (json['badges'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      rejectionReason: json['rejection_reason'] ?? '',
      websiteUrl: json['website_url'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      customLinks: (json['custom_links'] as List<dynamic>?)
              ?.map((e) => CustomLink.fromJson(e))
              .toList() ??
          [],
      screenshots: (json['screenshots'] as List<dynamic>?)
              ?.map((e) => GameScreenshot.fromJson(e))
              .toList() ??
          [],
      versions: (json['versions'] as List<dynamic>?)
              ?.map((e) => GameVersion.fromJson(e))
              .toList() ??
          [],
      issues: (json['issues'] as List<dynamic>?)
              ?.map((e) => GameIssue.fromJson(e))
              .toList() ??
          [],
      shortCode: json['short_code'] ?? '',
      publishedAt: json['published_at'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get statusLabel {
    switch (status) {
      case 'draft': return '草稿';
      case 'pending': return '审核中';
      case 'published': return '已上架';
      case 'rejected': return '已拒绝';
      case 'removed':
      case 'takedown': return '已下架';
      default: return status;
    }
  }

  String get priceTypeLabel {
    switch (priceType) {
      case 'free': return '免费';
      case 'paid': return '付费';
      case 'donation': return '捐赠支持';
      default: return priceType;
    }
  }
}

class CustomLink {
  final String label;
  final String url;
  final String action;

  CustomLink({
    this.label = '',
    this.url = '',
    this.action = 'open',
  });

  factory CustomLink.fromJson(Map<String, dynamic> json) {
    return CustomLink(
      label: json['label'] ?? '',
      url: json['url'] ?? '',
      action: json['action'] ?? 'open',
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'url': url,
    'action': action,
  };
}

Map<String, dynamic> gameToCreateJson({
  required String name,
  String subtitle = '',
  String shortDescription = '',
  String description = '',
  int? category,
  List<String> tags = const [],
  List<String> platforms = const [],
  String priceType = 'free',
  double price = 0,
  String donationUrl = '',
  String iconUrl = '',
  String coverUrl = '',
  String websiteUrl = '',
  String sourceUrl = '',
  String giteaRepo = '',
  String giteaRepoFullName = '',
  String giteaRepoUrl = '',
  String githubRepo = '',
  String githubRepoFullName = '',
  String githubRepoUrl = '',
  String distributeSoftware = '',
  List<CustomLink> customLinks = const [],
  List<Map<String, dynamic>> screenshots = const [],
}) {
  return {
    'name': name,
    'subtitle': subtitle,
    'short_description': shortDescription,
    'description': description,
    'category': category,
    'tags': tags,
    'platforms': platforms,
    'price_type': priceType,
    'price': price,
    'donation_url': donationUrl,
    'icon_url': iconUrl,
    'cover_url': coverUrl,
    'website_url': websiteUrl,
    'source_url': sourceUrl,
    'gitea_repo': giteaRepo,
    'gitea_repo_full_name': giteaRepoFullName,
    'gitea_repo_url': giteaRepoUrl,
    'github_repo': githubRepo,
    'github_repo_full_name': githubRepoFullName,
    'github_repo_url': githubRepoUrl,
    'distribute_software': distributeSoftware,
    'custom_links': customLinks.map((l) => l.toJson()).toList(),
    'screenshots': screenshots,
  };
}
