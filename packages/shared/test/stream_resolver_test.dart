import 'package:flutter_test/flutter_test.dart';
import 'package:anywhere_shared/stream_resolver.dart';

void main() {
  group('StreamResolver.selectLowestVariant (T-102)', () {
    const master = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=1280000,RESOLUTION=1280x720
https://example.com/720.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
https://example.com/360.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=2400000,RESOLUTION=1920x1080
https://example.com/1080.m3u8
''';

    test('targetHeight 이상 중 최저 해상도 선택', () {
      expect(selectLowestVariant(master, 360), 'https://example.com/360.m3u8');
    });

    test('targetHeight 미만은 제외', () {
      expect(selectLowestVariant(master, 480), 'https://example.com/720.m3u8');
    });

    test('targetHeight가 최고 해상도보다 크면 null', () {
      expect(selectLowestVariant(master, 2160), isNull);
    });

    test('비 HLS 본문이면 null', () {
      expect(selectLowestVariant('plain text', 360), isNull);
    });

    test('RESOLUTION 없는 variant는 건너뜀', () {
      const noRes = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000
https://example.com/audio.m3u8
''';
      expect(selectLowestVariant(noRes, 360), isNull);
    });

    test('상대 경로도 추출됨', () {
      const rel = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360
360/index.m3u8
''';
      expect(selectLowestVariant(rel, 360), '360/index.m3u8');
    });
  });
}