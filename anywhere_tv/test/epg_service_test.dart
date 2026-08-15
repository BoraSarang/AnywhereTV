import 'package:flutter_test/flutter_test.dart';
import 'package:anywhere_tv/services/epg_service.dart';

void main() {
  group('EpgService XMLTV 파서', () {
    const sampleXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE tv SYSTEM "xmltv.dtd">
<tv generator-info-name="epg2xml">
  <channel id="KBS1.KBS">
    <display-name>KBS 1TV</display-name>
  </channel>
  <programme start="20260815060000 +0900" stop="20260815073000 +0900" channel="KBS1.KBS">
    <title>뉴스라인</title>
    <desc>아침 뉴스</desc>
    <category>뉴스</category>
  </programme>
  <programme start="20260815073000 +0900" stop="20260815090000 +0900" channel="KBS1.KBS">
    <title>무엇이든 물어보세요</title>
    <desc>생활 정보 프로그램</desc>
    <category>교양</category>
  </programme>
</tv>
''';

    test('XMLTV 프로그램 파싱 및 채널 매칭', () {
      final programs = EpgService.parseXmltv(sampleXml, 'KBS1.KBS');
      expect(programs.length, 2);
      expect(programs[0].title, '뉴스라인');
      expect(programs[0].description, '아침 뉴스');
      expect(programs[0].category, '뉴스');
      expect(programs[1].title, '무엇이든 물어보세요');
      expect(programs[0].startTime.isBefore(programs[1].startTime), isTrue);
    });

    test('채널 id 접두사 매칭', () {
      final programs = EpgService.parseXmltv(sampleXml, 'KBS1');
      expect(programs.length, 2);
    });

    test('다른 채널은 매칭 안 됨', () {
      final programs = EpgService.parseXmltv(sampleXml, 'MBC');
      expect(programs.length, 0);
    });

    test('+0900 시간대 로컬 변환', () {
      final programs = EpgService.parseXmltv(sampleXml, 'KBS1');
      final start = programs[0].startTime;
      expect(start.toUtc(), DateTime.utc(2026, 8, 14, 21, 0));
    });
  });
}