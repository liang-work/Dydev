class Version {
  final String id;
  final String version;
  final int versionCode;
  final String versionType;
  final String title;
  final String releaseNotes;
  final String status;
  final String? channel;
  final String? channelName;
  final String directDownloadUrl;
  final int fileSize;
  final String fileHash;
  final String targetOs;
  final String targetArch;
  final bool isAbTest;
  final int downloadCount;
  final int grayPercentage;
  final String createdAt;
  final List<VersionAsset> assets;

  Version({
    required this.id,
    required this.version,
    this.versionCode = 0,
    this.versionType = 'patch',
    this.title = '',
    this.releaseNotes = '',
    this.status = 'draft',
    this.channel,
    this.channelName,
    this.directDownloadUrl = '',
    this.fileSize = 0,
    this.fileHash = '',
    this.targetOs = '',
    this.targetArch = '',
    this.isAbTest = false,
    this.downloadCount = 0,
    this.grayPercentage = 100,
    this.createdAt = '',
    this.assets = const [],
  });

  factory Version.fromJson(Map<String, dynamic> json) => Version(
        id: '${json['id']}',
        version: json['version'] as String? ?? '',
        versionCode: json['version_code'] as int? ?? 0,
        versionType: json['version_type'] as String? ?? 'patch',
        title: json['title'] as String? ?? '',
        releaseNotes: json['release_notes'] as String? ?? '',
        status: json['status'] as String? ?? 'draft',
        channel: json['channel'] as String?,
        channelName: json['channel_name'] as String?,
        directDownloadUrl: json['direct_download_url'] as String? ?? '',
        fileSize: json['file_size'] as int? ?? 0,
        fileHash: json['file_hash'] as String? ?? '',
        targetOs: json['target_os'] as String? ?? '',
        targetArch: json['target_arch'] as String? ?? '',
        isAbTest: json['is_ab_test'] as bool? ?? false,
        downloadCount: json['download_count'] as int? ?? 0,
        grayPercentage: json['gray_percentage'] as int? ?? 100,
        createdAt: json['created_at'] as String? ?? '',
        assets: (json['assets'] as List<dynamic>?)
                ?.map((e) => VersionAsset.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class VersionAsset {
  final String os;
  final String arch;
  final String downloadUrl;
  final int fileSize;

  VersionAsset({
    this.os = '',
    this.arch = '',
    this.downloadUrl = '',
    this.fileSize = 0,
  });

  factory VersionAsset.fromJson(Map<String, dynamic> json) => VersionAsset(
        os: json['os'] as String? ?? '',
        arch: json['arch'] as String? ?? '',
        downloadUrl: json['download_url'] as String? ?? '',
        fileSize: json['file_size'] as int? ?? 0,
      );
}
