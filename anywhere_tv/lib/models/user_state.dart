class UserState {
  final List<String> favoriteChannelIds;
  final String? lastWatchedChannelId;
  final String preferredResolution;
  final double lastVolume;

  const UserState({
    this.favoriteChannelIds = const [],
    this.lastWatchedChannelId,
    this.preferredResolution = '360',
    this.lastVolume = 0.5,
  });

  UserState copyWith({
    List<String>? favoriteChannelIds,
    String? lastWatchedChannelId,
    bool clearLastChannel = false,
    String? preferredResolution,
    double? lastVolume,
  }) {
    return UserState(
      favoriteChannelIds: favoriteChannelIds ?? this.favoriteChannelIds,
      lastWatchedChannelId: clearLastChannel ? null : (lastWatchedChannelId ?? this.lastWatchedChannelId),
      preferredResolution: preferredResolution ?? this.preferredResolution,
      lastVolume: lastVolume ?? this.lastVolume,
    );
  }
}
