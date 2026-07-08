class GameCategory {
  final int id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final int sortOrder;
  final bool isActive;
  final int gameCount;
  final String createdAt;

  GameCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon = '',
    this.description = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.gameCount = 0,
    this.createdAt = '',
  });

  factory GameCategory.fromJson(Map<String, dynamic> json) {
    return GameCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      gameCount: json['game_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'icon': icon,
    'description': description,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
}
