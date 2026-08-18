import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anywhere_shared/debug_logger.dart';
import 'ai_assistant_service.dart';
import 'youtube_meta_service.dart';

class AiChannelCandidate {
  final String name;
  final String description;
  final String? channelUrl;
  final String? logoUrl;
  final String? platform;

  const AiChannelCandidate({
    required this.name,
    required this.description,
    this.channelUrl,
    this.logoUrl,
    this.platform,
  });

  factory AiChannelCandidate.fromJson(Map<String, dynamic> json) {
    return AiChannelCandidate(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      channelUrl: (json['url'] as String? ?? '').trim().isEmpty
          ? null
          : (json['url'] as String).trim(),
      logoUrl: (json['logoUrl'] as String? ?? '').trim().isEmpty
          ? null
          : (json['logoUrl'] as String).trim(),
      platform: (json['platform'] as String? ?? '').trim().isEmpty
          ? null
          : (json['platform'] as String).trim(),
    );
  }
}

class AiSearchService {
  static final DebugLogger _log = DebugLogger.instance;

  static String _prompt({
    required String query,
    String? siteUrl,
  }) {
    if (siteUrl != null && siteUrl.isNotEmpty) {
      return '''
당신은 라이브 TV 채널 찾기 어시스턴트입니다. 웹 검색 도구를 사용하여 사이트 ${siteUrl}에서 시청 가능한 라이브 TV/유튜브 채널을 조사하세요.

반환 형식(코드 블록 마커, 설명 없이 JSON 배열만):
[{"name":"채널명","description":"한 줄 설명","url":"채널 또는 스트림 페이지 URL","platform":"youtube|youtube_handle|hls|기타"}]

규칙:
- 검색 결과에서 실제 확인 가능한 채널만 최대 10개
- youtube 채널이면 url은 https://www.youtube.com/... 형식
- .m3u8 등 직접 스트림 URL을 알면 그대로 사용
- 존재하지 않는 채널은 만들지 마세요
''';
    }
    return '''
당신은 라이브 TV 채널 찾기 어시스턴트입니다. 웹 검색 도구를 사용하여 아래 요청에 맞는 라이브 TV/유튜브 채널을 검색하세요.

요청: $query

반환 형식(코드 블록 마커, 설명 없이 JSON 배열만):
[{"name":"채널명","description":"한 줄 설명","url":"채널 또는 스트림 페이지 URL","platform":"youtube|youtube_handle|hls|기타"}]

규칙:
- 검색 결과에서 실제 확인 가능한 채널만 최대 10개
- youtube 채널이면 url은 https://www.youtube.com/... 형식
- .m3u8 등 직접 스트림 URL을 알면 그대로 사용
- 존재하지 않는 채널은 만들지 마세요
''';
  }

  static List<AiChannelCandidate>? parseCandidates(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '')
        .trim();
    final listStart = cleaned.indexOf('[');
    final listEnd = cleaned.lastIndexOf(']');
    if (listStart < 0 || listEnd <= listStart) return null;
    try {
      final decoded = jsonDecode(cleaned.substring(listStart, listEnd + 1));
      final items = (decoded as List<dynamic>)
          .map((e) => AiChannelCandidate.fromJson(e as Map<String, dynamic>))
          .where((c) => c.name.isNotEmpty)
          .toList();
      return items.isEmpty ? null : items;
    } catch (e) {
      _log.warn('AI', '후보 파싱 실패: $e');
      return null;
    }
  }

  static Future<(List<AiChannelCandidate>?, int?)> searchChannels({
    required String apiKey,
    required String query,
    String? siteUrl,
  }) async {
    final prompt = _prompt(query: query, siteUrl: siteUrl);
    _log.apiCall('AI', 'POST', 'generateContent (google_search)');
    int? lastStatus;

    for (final model in AiAssistantService.models) {
      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';
      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'tools': [
          {'google_search': {}},
        ],
      });
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 30));
        _log.apiResponse('AI', response.statusCode, 'generateContent ($model)');
        lastStatus = response.statusCode;
        if (response.statusCode == 429 || response.statusCode == 403) {
          _log.warn('AI', '할당량 초과 (${response.statusCode})');
          break;
        }
        if (response.statusCode != 200) {
          _log.warn('AI', 'HTTP ${response.statusCode}: ${response.body}');
          continue;
        }
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = json['candidates'] as List<dynamic>?;
        if (candidates == null || candidates.isEmpty) {
          _log.warn('AI', 'candidates 없음');
          continue;
        }
        final parts = (candidates.first as Map<String, dynamic>)['content']
            ?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) continue;
        final text = (parts.first as Map<String, dynamic>)['text'] as String?;
        if (text == null || text.isEmpty) continue;
        final items = parseCandidates(text);
        if (items == null) {
          _log.warn('AI', 'JSON 배열을 찾지 못함');
          continue;
        }
        _log.info('AI', '채널 검색 완료: ${items.length}건 ($model)');
        return (items, 200);
      } catch (e) {
        _log.error('AI', '검색 요청 실패: $e');
      }
    }

    if (lastStatus == 429 || lastStatus == 403) {
      if (siteUrl == null || siteUrl.isEmpty) {
        final fallback = await searchYoutube(query);
        if (fallback != null) {
          _log.info('AI', '유튜브 검색 폴백: ${fallback.length}건');
          return (fallback, 200);
        }
      }
      return (null, lastStatus);
    }
    return (null, lastStatus);
  }

  static Future<List<AiChannelCandidate>?> searchYoutube(String query) async {
    final encoded = Uri.encodeQueryComponent('$query 채널');
    final url = 'https://www.youtube.com/results?search_query=$encoded&sp=EgIQAg%3D%3D';
    _log.apiCall('AI', 'GET', 'youtube search (channels)');
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
              'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 10));
      _log.apiResponse('AI', response.statusCode, 'youtube search');
      if (response.statusCode != 200) return null;
      final json = YoutubeMetaService.extractInitialData(response.body);
      if (json == null) {
        _log.warn('AI', '유튜브 검색 파싱 실패');
        return null;
      }
      return parseYoutubeResults(json);
    } catch (e) {
      _log.error('AI', '유튜브 검색 실패: $e');
      return null;
    }
  }

  static List<AiChannelCandidate>? parseYoutubeResults(
      Map<String, dynamic> json) {
    final List<AiChannelCandidate> out = [];
    void visit(dynamic node) {
      if (node is Map<String, dynamic>) {
        final channel = node['channelRenderer'] as Map<String, dynamic>?;
        if (channel != null) {
          final title = channel['title']?['simpleText'] as String? ??
              channel['title']?['runs']?[0]?['text'] as String?;
          final channelId = channel['channelId'] as String?;
          String? avatar;
          try {
            avatar = channel['thumbnail']?['thumbnails']?[0]?['url'] as String?;
          } catch (_) {}
          String description = '';
          try {
            final runs = channel['descriptionSnippet']?['runs'] as List<dynamic>?;
            description = runs?.map((r) => r['text'] as String? ?? '').join() ?? '';
          } catch (_) {}
          if (title != null && title.isNotEmpty && channelId != null) {
            out.add(AiChannelCandidate(
              name: title.trim(),
              description: description.trim(),
              channelUrl: 'https://www.youtube.com/channel/$channelId',
              logoUrl: avatar,
              platform: 'youtube_handle',
            ));
          }
        }
        for (final v in node.values) {
          visit(v);
        }
      } else if (node is List) {
        for (final v in node) {
          visit(v);
        }
      }
    }

    visit(json);
    final unique = <String, AiChannelCandidate>{};
    for (final c in out) {
      unique.putIfAbsent(c.channelUrl ?? c.name, () => c);
    }
    final items = unique.values.take(10).toList();
    _log.info('AI', '유튜브 검색 결과: ${items.length}건');
    return items.isEmpty ? null : items;
  }
}
