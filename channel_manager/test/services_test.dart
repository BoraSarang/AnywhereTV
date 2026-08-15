import 'package:flutter_test/flutter_test.dart';
import 'package:channel_manager/models/channel.dart';
import 'package:channel_manager/services/diff_service.dart';
import 'package:channel_manager/services/m3u_service.dart';
import 'package:channel_manager/services/validation_service.dart';

Channel _channel(String id, String name, {String category = '지상파', String? url}) {
  return Channel(
    id: id,
    name: name,
    logoUrl: '',
    streamUrl: url,
    category: category,
    sourceType: url != null ? 'hls' : 'youtube_handle',
    youtubeHandle: url == null ? '@$id' : null,
  );
}

void main() {
  group('ValidationService', () {
    test('중복 이름/URL/핸들을 감지한다', () {
      final channels = [
        _channel('kbs1', 'KBS1', url: 'https://a.m3u8'),
        _channel('kbs1_dup', 'KBS1', url: 'https://a.m3u8'),
        _channel('jtbc', 'JTBC', url: 'https://b.m3u8'),
      ];
      final issues = ValidationService.validate(
        channels: channels,
        categories: const ['지상파'],
      );
      final messages = issues.map((i) => i.message).join('\n');
      expect(messages, contains('이름 중복'));
      expect(messages, contains('스트림 URL 중복'));
    });

    test('스트림 소스 없는 채널을 error로 보고한다', () {
      final channels = [
        Channel(
          id: 'empty',
          name: '빈채널',
          logoUrl: '',
          category: '지상파',
          sourceType: 'hls',
        ),
      ];
      final issues = ValidationService.validate(
        channels: channels,
        categories: const ['지상파'],
      );
      expect(
        issues.any((i) =>
            i.severity == ValidationSeverity.error &&
            i.message.contains('스트림 소스')),
        isTrue,
      );
    });

    test('로고 URL 형식이 잘못되면 경고한다', () {
      final channels = [
        Channel(
          id: 'badlogo',
          name: '테스트',
          logoUrl: 'not-a-url',
          streamUrl: 'https://a.m3u8',
          category: '지상파',
          sourceType: 'hls',
        ),
      ];
      final issues = ValidationService.validate(
        channels: channels,
        categories: const ['지상파'],
      );
      expect(
        issues.any((i) => i.message.contains('로고 URL 형식')),
        isTrue,
      );
    });
  });

  group('DiffService', () {
    test('추가/삭제/수정을 구분한다', () {
      final oldChannels = [
        _channel('a', 'A', url: 'https://a.m3u8'),
        _channel('b', 'B', url: 'https://b.m3u8'),
      ];
      final newChannels = [
        _channel('a', 'A', url: 'https://a.m3u8'),
        _channel('b', 'B변경', category: '케이블', url: 'https://b.m3u8'),
        _channel('c', 'C', url: 'https://c.m3u8'),
      ];
      final diff = DiffService.diff(
        oldChannels: oldChannels,
        newChannels: newChannels,
      );
      expect(diff.added.single.id, 'c');
      expect(diff.removed, isEmpty);
      expect(diff.modified.single.channel.id, 'b');
      expect(diff.modified.single.changedFields, containsAll(['이름', '카테고리']));
    });
  });

  group('M3uService', () {
    test('내보낸 M3U를 다시 파싱하면 채널이 복원된다', () {
      final channels = [
        _channel('kbs1', 'KBS1', category: '지상파', url: 'https://a.m3u8'),
        _channel('jtbc', 'JTBC', url: 'https://b.m3u8'),
      ];
      final content = M3uService.export(channels);
      expect(content, startsWith('#EXTM3U'));
      expect(content, contains('#EXTINF'));
      expect(content, contains('group-title="지상파"'));

      final entries = M3uService.parse(content);
      expect(entries.length, 2);
      expect(entries[0].name, 'KBS1');
      expect(entries[0].groupTitle, '지상파');
      expect(entries[0].url, 'https://a.m3u8');
    });

    test('YouTube URL의 소스 유형을 감지한다', () {
      expect(M3uService.detectSourceType('https://www.youtube.com/@KBSNEWS/live'),
          'youtube_handle');
      expect(M3uService.detectSourceType('https://youtu.be/abc123def45'),
          'youtube');
      expect(M3uService.detectSourceType('https://x.m3u8'), 'hls');
    });
  });

  group('Channel backupStreamUrl', () {
    test('직렬화/역직렬화가 유지된다', () {
      final channel = Channel(
        id: 'a',
        name: 'A',
        logoUrl: '',
        streamUrl: 'https://a.m3u8',
        backupStreamUrl: 'https://backup.m3u8',
        category: '지상파',
        sourceType: 'hls',
      );
      final restored = Channel.fromJson(channel.toJson());
      expect(restored.backupStreamUrl, 'https://backup.m3u8');
    });
  });
}