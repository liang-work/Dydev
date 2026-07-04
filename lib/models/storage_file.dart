class StorageFile {
  final String key;
  final String name;
  final String path;
  final bool isDirectory;
  final int size;
  final String sizeFormatted;
  final String lastModified;

  StorageFile({
    required this.key,
    required this.name,
    required this.path,
    this.isDirectory = false,
    this.size = 0,
    this.sizeFormatted = '',
    this.lastModified = '',
  });

  factory StorageFile.fromJson(Map<String, dynamic> json) => StorageFile(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        path: json['path'] as String? ?? '',
        isDirectory: json['is_directory'] as bool? ?? false,
        size: json['size'] as int? ?? 0,
        sizeFormatted: json['size_formatted'] as String? ?? '',
        lastModified: json['last_modified'] as String? ?? '',
      );
}
