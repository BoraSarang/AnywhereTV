import '../models/channel.dart';

class ChannelDiff {
  final List<Channel> added;
  final List<Channel> removed;
  final List<ModifiedChannel> modified;

  const ChannelDiff({
    required this.added,
    required this.removed,
    required this.modified,
  });

  bool get isEmpty => added.isEmpty && removed.isEmpty && modified.isEmpty;
  int get total => added.length + removed.length + modified.length;
}

class ModifiedChannel {
  final Channel channel;
  final List<String> changedFields;

  const ModifiedChannel({required this.channel, required this.changedFields});
}

class DiffService {
  static ChannelDiff diff({
    required List<Channel> oldChannels,
    required List<Channel> newChannels,
  }) {
    final oldById = {for (final c in oldChannels) c.id: c};
    final newById = {for (final c in newChannels) c.id: c};

    final added = <Channel>[];
    final removed = <Channel>[];
    final modified = <ModifiedChannel>[];

    for (final entry in newById.entries) {
      if (!oldById.containsKey(entry.key)) {
        added.add(entry.value);
      }
    }
    for (final entry in oldById.entries) {
      if (!newById.containsKey(entry.key)) {
        removed.add(entry.value);
      }
    }
    for (final entry in newById.entries) {
      final old = oldById[entry.key];
      if (old == null) continue;
      final changed = _changedFields(old, entry.value);
      if (changed.isNotEmpty) {
        modified.add(ModifiedChannel(channel: entry.value, changedFields: changed));
      }
    }

    return ChannelDiff(added: added, removed: removed, modified: modified);
  }

  static List<String> _changedFields(Channel old, Channel now) {
    final fields = <String>[];
    if (old.name != now.name) fields.add('이름');
    if (old.category != now.category) fields.add('카테고리');
    if (old.logoUrl != now.logoUrl) fields.add('로고');
    if (old.streamUrl != now.streamUrl) fields.add('스트림 URL');
    if (old.youtubeHandle != now.youtubeHandle) fields.add('YouTube 핸들');
    if (old.youtubeVideoId != now.youtubeVideoId) fields.add('YouTube 동영상');
    if (old.sourceType != now.sourceType) fields.add('소스 유형');
    return fields;
  }
}