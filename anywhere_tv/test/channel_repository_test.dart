import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anywhere_tv/repositories/channel_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelRepository (T-102)', () {
    test('bundle에서 채널 로드', () async {
      final repo = ChannelRepository();
      await repo.init();
      expect(repo.channels.length, greaterThanOrEqualTo(30));
      expect(repo.currentVersion, greaterThan(0));
    });

    test('getById 존재/미존재', () async {
      final repo = ChannelRepository();
      await repo.init();
      expect(repo.getById('kbs1'), isNotNull);
      expect(repo.getById('nonexistent'), isNull);
    });

    test('캐시가 번들보다 최신이면 캐시 우선', () async {
      SharedPreferences.setMockInitialValues({
        'cached_channels_data': jsonEncode({
          'version': 999,
          'channels': [
            {
              'id': 'test1',
              'name': '테스트채널',
              'category': '테스트',
              'sourceType': 'hls',
              'isDefaultFavorite': false,
              'streamUrl': 'https://example.com/live.m3u8',
            }
          ],
        }),
      });
      final repo = ChannelRepository();
      await repo.init();
      expect(repo.currentVersion, 999);
      expect(repo.channels.length, 1);
      expect(repo.channels.first.id, 'test1');
    });

    test('캐시가 번들보다 오래되면 번들 유지', () async {
      SharedPreferences.setMockInitialValues({
        'cached_channels_data': jsonEncode({
          'version': 1,
          'channels': [
            {
              'id': 'old1',
              'name': '오래된',
              'category': '테스트',
              'sourceType': 'hls',
              'isDefaultFavorite': false,
            }
          ],
        }),
      });
      final repo = ChannelRepository();
      await repo.init();
      expect(repo.currentVersion, greaterThan(1));
      expect(repo.getById('old1'), isNull);
    });

    test('defaultFavorites 반환', () async {
      final repo = ChannelRepository();
      await repo.init();
      final favs = repo.defaultFavorites;
      expect(favs, isNotEmpty);
      for (final c in favs) {
        expect(c.isDefaultFavorite, isTrue);
      }
    });
  });
}