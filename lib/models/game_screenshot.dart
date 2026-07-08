class GameScreenshot {
  final int id;
  final String imageUrl;
  final String videoUrl;
  final int sortOrder;

  GameScreenshot({
    this.id = 0,
    this.imageUrl = '',
    this.videoUrl = '',
    this.sortOrder = 0,
  });

  factory GameScreenshot.fromJson(Map<String, dynamic> json) {
    return GameScreenshot(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
      sortOrder: json['sort_order'] ?? 0,
    );
  }
}
