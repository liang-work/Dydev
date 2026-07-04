class ConfigItem {
  final String id;
  final String key;
  final dynamic value;
  final String description;
  final bool isActive;
  final String software;
  final String updatedAt;

  ConfigItem({
    required this.id,
    required this.key,
    this.value,
    this.description = '',
    this.isActive = true,
    this.software = '',
    this.updatedAt = '',
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) => ConfigItem(
        id: '${json['id']}',
        key: json['key'] as String? ?? '',
        value: json['value'],
        description: json['description'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        software: json['software'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
      );
}
