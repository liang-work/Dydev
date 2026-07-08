class GameIssue {
  final int id;
  final int game;
  final int user;
  final String username;
  final String userAvatar;
  final bool isOwner;
  final String title;
  final String content;
  final String issueType;
  final String status;
  final String createdAt;
  final String updatedAt;

  GameIssue({
    this.id = 0,
    this.game = 0,
    this.user = 0,
    this.username = '',
    this.userAvatar = '',
    this.isOwner = false,
    this.title = '',
    this.content = '',
    this.issueType = 'question',
    this.status = 'open',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory GameIssue.fromJson(Map<String, dynamic> json) {
    return GameIssue(
      id: json['id'] ?? 0,
      game: json['game'] ?? 0,
      user: json['user'] ?? 0,
      username: json['username'] ?? '',
      userAvatar: json['user_avatar'] ?? '',
      isOwner: json['is_owner'] as bool? ?? false,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      issueType: json['issue_type'] ?? 'question',
      status: json['status'] ?? 'open',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  String get issueTypeLabel {
    switch (issueType) {
      case 'bug': return 'Bug';
      case 'feature': return '功能建议';
      case 'question': return '问题咨询';
      default: return '其他';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open': return '待处理';
      case 'confirmed': return '已确认';
      case 'in_progress': return '处理中';
      case 'resolved': return '已解决';
      case 'closed': return '已关闭';
      default: return status;
    }
  }
}
