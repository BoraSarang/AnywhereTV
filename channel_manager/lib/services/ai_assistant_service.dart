import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anywhere_shared/debug_logger.dart';

class AiAssistantService {
  static const List<String> models = ['gemini-3.5-flash', 'gemini-3.1-flash-lite'];
  static final DebugLogger _log = DebugLogger.instance;

  static Future<String?> generateChannelsJson({
    required String apiKey,
    required String currentJson,
    required String instruction,
  }) async {
    final prompt = '''
당신은 채널 목록 편집 어시스턴트입니다. 아래 채널 목록 JSON을 사용자 지시에 따라 수정하고,
수정된 전체 JSON만 반환하세요.

규칙:
- JSON 형식은 반드시 유지: {"version":N,"updatedAt":"...","remoteUrl":"...","categories":[...],"history":[...],"channels":[...]}
- channels 항목의 각 채널 필드: id, name, logoUrl, streamUrl, youtubeChannelId, youtubeVideoId, youtubeHandle, category, sourceType, isDefaultFavorite, resolver, resolverData
- 새 카테고리를 만들면 categories 배열에도 반드시 추가하세요.
- 채널 삭제는 channels 배열에서 제거하는 방식입니다.
- 설명 텍스트, 코드 블록 마커(```) 없이 JSON 본문만 반환하세요.
- 수정할 것이 없으면 입력 JSON을 그대로 반환하세요.

현재 JSON:
$currentJson

사용자 지시:
$instruction
''';

    _log.apiCall('AI', 'POST', 'generateContent');
    for (final model in models) {
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
      });
      try {
        final response = await http
            .post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
            .timeout(const Duration(seconds: 60));
        _log.apiResponse('AI', response.statusCode, 'generateContent ($model)');
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = json['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            _log.error('AI', 'candidates 없음');
            return null;
          }
          final parts = (candidates.first as Map<String, dynamic>)['content']
              ?['parts'] as List<dynamic>?;
          if (parts == null || parts.isEmpty) return null;
          final text = (parts.first as Map<String, dynamic>)['text'] as String?;
          if (text == null) return null;
          return text.trim();
        }
        _log.warn('AI', 'HTTP ${response.statusCode}: ${response.body}');
      } catch (e) {
        _log.error('AI', '요청 실패: $e');
      }
    }
    _log.error('AI', '모든 모델 실패');
    return null;
  }
}