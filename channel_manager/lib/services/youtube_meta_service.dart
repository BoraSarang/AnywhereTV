import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anywhere_shared/debug_logger.dart';

class YoutubeChannelMeta {
  final String name;
  final String? channelId;
  final String? handle;
  final String? avatarUrl;
  final String description;

  const YoutubeChannelMeta({
    required this.name,
    this.channelId,
    this.handle,
    this.avatarUrl,
    this.description = '',
  });
}

class YoutubeMetaService {
  static final DebugLogger _log = DebugLogger.instance;

  static String? extractHandle(String url) {
    final match = RegExp(r'youtube\.com/@([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  static String? extractChannelId(String url) {
    final match =
        RegExp(r'youtube\.com/channel/(UC[a-zA-Z0-9_-]{22})').firstMatch(url);
    return match?.group(1);
  }

  static Future<YoutubeChannelMeta?> fetch(String url) async {
    final handle = extractHandle(url);
    final channelId = extractChannelId(url);
    if (handle == null && channelId == null) return null;

    final fetchUrl = channelId != null
        ? 'https://www.youtube.com/channel/$channelId'
        : 'https://www.youtube.com/@$handle';
    _log.apiCall('AI', 'GET', 'youtube channel page');
    try {
      final response = await http
          .get(
            Uri.parse(fetchUrl),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
              'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 10));
      _log.apiResponse('AI', response.statusCode, 'youtube channel page');
      if (response.statusCode != 200) return null;

      final body = response.body;
      final json = _extractInitialData(body);
      if (json == null) {
        _log.warn('AI', 'ytInitialData 파싱 실패');
        return null;
      }

      final header =
          json['header']?['c4TabbedHeaderRenderer'] as Map<String, dynamic>?;
      final metadata =
          json['metadata']?['channelMetadataRenderer'] as Map<String, dynamic>?;
      final microformat =
          json['microformat']?['microformatDataRenderer'] as Map<String, dynamic>?;

      final name = (header?['title'] as String?) ??
          (metadata?['title'] as String?) ??
          (microformat?['title'] as String?) ??
          handle ??
          '';
      final resolvedChannelId =
          (metadata?['channelId'] as String?) ??
          (metadata?['externalId'] as String?) ??
          (microformat?['channelExternalId'] as String?) ??
          channelId;
      final description = (metadata?['description'] as String?) ??
          (microformat?['description'] as String?) ??
          '';
      String? avatarUrl;
      try {
        avatarUrl = header?['avatar']?['channelThumbnailViewModel']
            ?['thumbnail']?['thumbnails']?[0]?['url'] as String?;
      } catch (_) {}

      final meta = YoutubeChannelMeta(
        name: name.trim(),
        channelId: resolvedChannelId,
        handle: handle,
        avatarUrl: avatarUrl,
        description: description.trim(),
      );
      _log.info('AI', '유튜브 메타: ${meta.name} (@$handle, id=${meta.channelId})');
      return meta;
    } catch (e) {
      _log.error('AI', '유튜브 페이지 요청 실패: $e');
      return null;
    }
  }

  static Map<String, dynamic>? extractInitialData(String body) {
    return _extractInitialData(body);
  }

  static Map<String, dynamic>? _extractInitialData(String body) {
    final marker = 'ytInitialData';
    final idx = body.indexOf(marker);
    if (idx < 0) return null;
    final braceStart = body.indexOf('{', idx);
    if (braceStart < 0) return null;
    int depth = 0;
    for (int i = braceStart; i < body.length; i++) {
      if (body[i] == '{') {
        depth++;
        continue;
      }
      if (body[i] == '}') {
        depth--;
        if (depth == 0) {
          try {
            return jsonDecode(body.substring(braceStart, i + 1))
                as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }
}
