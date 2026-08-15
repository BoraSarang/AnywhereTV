import '../models/channel.dart';

class M3uEntry {
  final String name;
  final String logoUrl;
  final String groupTitle;
  final String url;

  const M3uEntry({
    required this.name,
    required this.logoUrl,
    required this.groupTitle,
    required this.url,
  });
}

class M3uService {
  static String export(List<Channel> channels) {
    final buf = StringBuffer();
    buf.writeln('#EXTM3U');
    for (final ch in channels) {
      final attrs = <String>[];
      if (ch.logoUrl.isNotEmpty) attrs.add('tvg-logo="${ch.logoUrl}"');
      if (ch.category.isNotEmpty) attrs.add('group-title="${ch.category}"');
      final attrStr = attrs.isEmpty ? '' : ' ${attrs.join(' ')}';
      buf.writeln('#EXTINF:-1$attrStr ,${ch.name}');
      final url = _sourceUrl(ch);
      if (url != null) buf.writeln(url);
    }
    return buf.toString();
  }

  static String? _sourceUrl(Channel ch) {
    if (ch.streamUrl != null && ch.streamUrl!.isNotEmpty) return ch.streamUrl;
    if (ch.youtubeHandle != null && ch.youtubeHandle!.isNotEmpty) {
      return 'https://www.youtube.com/${ch.youtubeHandle}/live';
    }
    if (ch.youtubeVideoId != null && ch.youtubeVideoId!.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=${ch.youtubeVideoId}';
    }
    return null;
  }

  static List<M3uEntry> parse(String content) {
    final entries = <M3uEntry>[];
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.startsWith('#EXTINF')) continue;
      final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
      final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
      final namePart = line.substring(line.lastIndexOf(',') + 1).trim();
      String? url;
      for (var j = i + 1; j < lines.length; j++) {
        final next = lines[j].trim();
        if (next.isEmpty || next.startsWith('#')) continue;
        url = next;
        break;
      }
      if (namePart.isEmpty || url == null) continue;
      entries.add(M3uEntry(
        name: namePart,
        logoUrl: logoMatch?.group(1) ?? '',
        groupTitle: groupMatch?.group(1) ?? '',
        url: url,
      ));
    }
    return entries;
  }

  static String detectSourceType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      if (url.contains('/@') ||
          RegExp(r'youtube\.com/(c/|channel/|@)').hasMatch(url)) {
        return 'youtube_handle';
      }
      return 'youtube';
    }
    return 'hls';
  }

  static String? extractHandle(String url) {
    final match = RegExp(r'youtube\.com/@([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  static String? extractVideoId(String url) {
    final match =
        RegExp(r'(?:v=|youtu\.be/|/shorts/)([a-zA-Z0-9_-]{11})').firstMatch(url);
    return match?.group(1);
  }
}