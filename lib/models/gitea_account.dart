class GiteaAccount {
  final bool connected;
  final String? giteaUsername;
  final int? giteaId;
  final String? giteaConnectedAt;

  GiteaAccount({
    this.connected = false,
    this.giteaUsername,
    this.giteaId,
    this.giteaConnectedAt,
  });

  factory GiteaAccount.fromJson(Map<String, dynamic> json) => GiteaAccount(
        connected: json['connected'] as bool? ?? false,
        giteaUsername: json['gitea_username'] as String?,
        giteaId: json['gitea_id'] as int?,
        giteaConnectedAt: json['gitea_connected_at'] as String?,
      );
}
