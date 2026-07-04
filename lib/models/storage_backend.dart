class StorageBackend {
  final String id;
  final String name;
  final String storageType;
  final bool isActive;
  final String defaultLinkType;
  final String? s3Endpoint;
  final String? s3Bucket;
  final String? s3Region;
  final String? s3PathPrefix;
  final String? webdavUrl;
  final String? webdavUsername;
  final String? webdavPathPrefix;
  final String? cdnDomain;
  final String? cdnPathPrefix;

  StorageBackend({
    required this.id,
    required this.name,
    required this.storageType,
    this.isActive = true,
    this.defaultLinkType = 'direct',
    this.s3Endpoint,
    this.s3Bucket,
    this.s3Region,
    this.s3PathPrefix,
    this.webdavUrl,
    this.webdavUsername,
    this.webdavPathPrefix,
    this.cdnDomain,
    this.cdnPathPrefix,
  });

  factory StorageBackend.fromJson(Map<String, dynamic> json) =>
      StorageBackend(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        storageType: json['storage_type'] as String? ?? 's3',
        isActive: json['is_active'] as bool? ?? true,
        defaultLinkType: json['default_link_type'] as String? ?? 'direct',
        s3Endpoint: json['s3_endpoint'] as String?,
        s3Bucket: json['s3_bucket'] as String?,
        s3Region: json['s3_region'] as String?,
        s3PathPrefix: json['s3_path_prefix'] as String?,
        webdavUrl: json['webdav_url'] as String?,
        webdavUsername: json['webdav_username'] as String?,
        webdavPathPrefix: json['webdav_path_prefix'] as String?,
        cdnDomain: json['cdn_domain'] as String?,
        cdnPathPrefix: json['cdn_path_prefix'] as String?,
      );
}
