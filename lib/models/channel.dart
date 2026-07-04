class Channel {
  final String id;
  final String name;
  final String channelType;
  final bool isActive;

  Channel({
    required this.id,
    required this.name,
    required this.channelType,
    this.isActive = true,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        channelType: json['channel_type'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
      );
}
