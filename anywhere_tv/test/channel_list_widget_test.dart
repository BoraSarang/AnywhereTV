import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anywhere_tv/repositories/channel_repository.dart';
import 'package:anywhere_tv/ui/channel_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChannelListScreen 위젯 (T-102)', () {
    testWidgets('채널 목록 렌더링', (tester) async {
      final repo = ChannelRepository();
      await tester.pumpWidget(MaterialApp(
        home: ChannelListScreen(
          channelRepo: repo,
          favoriteChannelIds: const [],
          onFavoritesChanged: (_) {},
          watchHistory: const [],
        ),
      ));
      await tester.pump();
      expect(find.byType(ChannelListScreen), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('채널 검색...'), findsOneWidget);
    });
  });
}