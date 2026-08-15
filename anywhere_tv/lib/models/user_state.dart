class UserState {
  final List<String> favoriteChannelIds;
  final String? lastWatchedChannelId;
  final String preferredResolution;
  final double lastVolume;
  final bool ttsEnabled;
  final bool broadcastAlertsEnabled;
  final String? epgServerUrl;

  const UserState({
    this.favoriteChannelIds = const [],
    this.lastWatchedChannelId,
    this.preferredResolution = '360',
    this.lastVolume = 0.5,
    this.ttsEnabled = false,
    this.broadcastAlertsEnabled = false,
    this.epgServerUrl,
  });

  UserState copyWith({
    List<String>? favoriteChannelIds,
    String? lastWatchedChannelId,
    bool clearLastChannel = false,
    String? preferredResolution,
    double? lastVolume,
    bool? ttsEnabled,
    bool? broadcastAlertsEnabled,
    String? epgServerUrl,
    bool clearEpgServerUrl = false,
  }) {
    return UserState(
      favoriteChannelIds: favoriteChannelIds ?? this.favoriteChannelIds,
      lastWatchedChannelId: clearLastChannel ? null : (lastWatchedChannelId ?? this.lastWatchedChannelId),
      preferredResolution: preferredResolution ?? this.preferredResolution,
      lastVolume: lastVolume ?? this.lastVolume,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      broadcastAlertsEnabled: broadcastAlertsEnabled ?? this.broadcastAlertsEnabled,
      epgServerUrl: clearEpgServerUrl ? null : (epgServerUrl ?? this.epgServerUrl),
    );
  }
}