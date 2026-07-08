class GameVersion {
  final int id;
  final String version;
  final String platform;
  final String fileUrl;
  final int fileSize;
  final String fileHash;
  final String releaseNotes;
  final bool isLatest;
  final int downloadCount;
  final String createdAt;

  GameVersion({
    this.id = 0,
    this.version = '',
    this.platform = '',
    this.fileUrl = '',
    this.fileSize = 0,
    this.fileHash = '',
    this.releaseNotes = '',
    this.isLatest = false,
    this.downloadCount = 0,
    this.createdAt = '',
  });

  factory GameVersion.fromJson(Map<String, dynamic> json) {
    return GameVersion(
      id: json['id'] ?? 0,
      version: json['version'] ?? '',
      platform: json['platform'] ?? '',
      fileUrl: json['file_url'] ?? '',
      fileSize: json['file_size'] ?? 0,
      fileHash: json['file_hash'] ?? '',
      releaseNotes: json['release_notes'] ?? '',
      isLatest: json['is_latest'] as bool? ?? false,
      downloadCount: json['download_count'] ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }

  String get fileSizeDisplay {
    final size = fileSize;
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
