class TelemetryData {
  final int id;
  final String dataType;
  final String softwareName;
  final String software;
  final String version;
  final String environment;
  final String? deviceId;
  final String? ipAddress;
  final dynamic content;
  final String timestamp;

  TelemetryData({
    required this.id,
    this.dataType = 'metric',
    this.softwareName = '',
    this.software = '',
    this.version = '',
    this.environment = '',
    this.deviceId,
    this.ipAddress,
    this.content,
    this.timestamp = '',
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) => TelemetryData(
        id: json['id'] as int? ?? 0,
        dataType: json['data_type'] as String? ?? 'metric',
        softwareName: json['software_name'] as String? ?? '',
        software: json['software'] as String? ?? '',
        version: json['version'] as String? ?? '',
        environment: json['environment'] as String? ?? '',
        deviceId: json['device_id'] as String?,
        ipAddress: json['ip_address'] as String?,
        content: json['content'],
        timestamp: json['timestamp'] as String? ?? '',
      );
}
