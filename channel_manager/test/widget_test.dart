import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:channel_manager/main.dart';

void main() {
  testWidgets('앱 빌드 스모크 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const ChannelManagerApp());
    await tester.pumpAndSettle();
    expect(find.byType(Scaffold), findsWidgets);
  });
}