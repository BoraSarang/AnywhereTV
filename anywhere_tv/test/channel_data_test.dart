import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('channels.json 데이터 검증 (T-110 파이프라인)', () {
    late Map<String, dynamic> data;
    late List<dynamic> channels;

    setUpAll(() async {
      final raw = await rootBundle.loadString('assets/channels.json');
      data = jsonDecode(raw) as Map<String, dynamic>;
      channels = data['channels'] as List;
    });

    test('채널 수 30~50개', () {
      expect(channels.length, greaterThanOrEqualTo(30));
      expect(channels.length, lessThanOrEqualTo(50));
    });

    test('id 중복 없음', () {
      final ids = channels.map((c) => c['id'] as String).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('필수 필드 존재 (id, name, category, sourceType, isDefaultFavorite)', () {
      for (final c in channels) {
        expect(c['id'], isNotNull, reason: '${c['name']} id 누락');
        expect(c['name'], isNotNull, reason: '${c['id']} name 누락');
        expect(c['category'], isNotNull, reason: '${c['id']} category 누락');
        expect(c['sourceType'], isNotNull, reason: '${c['id']} sourceType 누락');
        expect(c['isDefaultFavorite'], isNotNull, reason: '${c['id']} isDefaultFavorite 누락');
      }
    });

    test('sourceType 유효성 (youtube_live | hls)', () {
      for (final c in channels) {
        expect(
          ['youtube_live', 'hls'],
          contains(c['sourceType']),
          reason: '${c['id']} 잘못된 sourceType: ${c['sourceType']}',
        );
      }
    });

    test('youtube_live는 youtubeHandle 또는 youtubeVideoId 필요', () {
      for (final c in channels) {
        if (c['sourceType'] == 'youtube_live') {
          final handle = c['youtubeHandle'] as String?;
          final videoId = c['youtubeVideoId'] as String?;
          expect(
            (handle != null && handle.isNotEmpty) || (videoId != null && videoId.isNotEmpty),
            isTrue,
            reason: '${c['id']} youtube 핸들/ID 누락',
          );
          if (handle != null && handle.isNotEmpty) {
            expect(handle.startsWith('@'), isTrue, reason: '${c['id']} 핸들 형식');
          }
        }
      }
    });

    test('hls는 streamUrl 또는 resolver 필요', () {
      for (final c in channels) {
        if (c['sourceType'] == 'hls') {
          final url = c['streamUrl'] as String?;
          final resolver = c['resolver'] as String?;
          expect(
            (url != null && url.isNotEmpty) || (resolver != null && resolver.isNotEmpty),
            isTrue,
            reason: '${c['id']} streamUrl/resolver 누락',
          );
          if (url != null && url.isNotEmpty) {
            expect(
              url.startsWith('http'),
              isTrue,
              reason: '${c['id']} URL 형식: $url',
            );
          }
        }
      }
    });

    test('버전/업데이트 필드 존재', () {
      expect(data['version'], isNotNull);
      expect(data['updatedAt'], isNotNull);
    });
  });
}