import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../data/app_database.dart';
import '../models/epg_program.dart';
import 'package:anywhere_shared/debug_logger.dart';

class EpgService {
  static final DebugLogger _log = DebugLogger.instance;

  static AppDatabase? _db;

  static Future<AppDatabase> get _database async {
    return _db ??= AppDatabase();
  }

  static const _cacheTtl = Duration(hours: 6);

  static Future<List<EpgProgram>> fetchFromUrl(String url, String channelId) async {
    try {
      final db = await _database;
      final lastFetch = await db.lastEpgFetch(channelId);
      final cached = await db.loadEpgCache(channelId);
      final isFresh = lastFetch != null &&
          DateTime.now().difference(lastFetch) < _cacheTtl &&
          cached.isNotEmpty;
      if (isFresh) {
        _log.system('EPG', 'Cache hit: $channelId (${cached.length} programs)');
        return cached;
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        if (cached.isNotEmpty) {
          _log.warn('EPG', 'Fetch failed(${response.statusCode}), using cache: $channelId');
          return cached;
        }
        return [];
      }
      final body = response.body.trim();
      List<EpgProgram> programs;

      if (body.startsWith('[')) {
        final list = jsonDecode(body) as List;
        programs = list
            .map((e) => EpgProgram.fromJson(e as Map<String, dynamic>))
            .where((p) => p.channelId == channelId)
            .toList();
      } else if (body.startsWith('{')) {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final channels = map['channels'] as List? ?? [];
        programs = [];
        for (final ch in channels) {
          if ((ch as Map)['id'] == channelId) {
            final list = ch['programs'] as List? ?? [];
            programs = list
                .map((e) => EpgProgram.fromJson(e as Map<String, dynamic>))
                .toList();
            break;
          }
        }
      } else if (body.contains('<tv') && body.contains('<programme')) {
        programs = parseXmltv(body, channelId);
      } else {
        programs = cached;
      }

      if (programs.isNotEmpty) {
        await db.saveEpgCache(programs, channelId);
        _log.system('EPG', 'Cache saved: $channelId (${programs.length} programs)');
      }
      return programs;
    } catch (e) {
      _log.warn('EPG', 'fetchFromUrl failed: $e');
      try {
        final db = await _database;
        return await db.loadEpgCache(channelId);
      } catch (_) {
        return [];
      }
    }
  }

  static List<EpgProgram> parseXmltv(String xml, String channelId) {
    final programs = <EpgProgram>[];
    try {
      final document = XmlDocument.parse(xml);
      final tv = document.findAllElements('tv').firstOrNull;
      if (tv == null) return programs;
      for (final prog in tv.findAllElements('programme')) {
        final ch = prog.getAttribute('channel') ?? '';
        if (!ch.startsWith(channelId) && !ch.contains(channelId)) continue;
        final start = _parseXmltvTime(prog.getAttribute('start') ?? '');
        final stop = _parseXmltvTime(prog.getAttribute('stop') ?? '');
        final title = prog.findElements('title').firstOrNull?.innerText ?? '';
        if (start == null || title.isEmpty) continue;
        programs.add(EpgProgram(
          channelId: channelId,
          title: title,
          startTime: start,
          endTime: stop ?? start.add(const Duration(hours: 1)),
          description: prog.findElements('desc').firstOrNull?.innerText,
          category: prog.findElements('category').firstOrNull?.innerText,
        ));
      }
      programs.sort((a, b) => a.startTime.compareTo(b.startTime));
    } catch (e) {
      _log.warn('EPG', 'parseXmltv failed: $e');
    }
    return programs;
  }

  static DateTime? _parseXmltvTime(String value) {
    if (value.isEmpty) return null;
    final m = RegExp(r'^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})').firstMatch(value);
    if (m == null) return null;
    final tz = RegExp(r'([+-]\d{4})').firstMatch(value)?.group(1);
    var dt = DateTime.utc(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
      int.parse(m.group(4)!),
      int.parse(m.group(5)!),
      int.parse(m.group(6)!),
    );
    if (tz != null) {
      final offsetMin = int.parse(tz.substring(1, 3)) * 60 + int.parse(tz.substring(3));
      final sign = tz.startsWith('-') ? -1 : 1;
      dt = dt.subtract(Duration(minutes: sign * offsetMin));
    }
    return dt.toLocal();
  }

  static EpgProgram? currentProgram(List<EpgProgram> programs) {
    try {
      return programs.firstWhere((p) => p.isCurrentlyAiring);
    } catch (_) {}
    return null;
  }

  static EpgProgram? nextProgram(List<EpgProgram> programs) {
    final now = DateTime.now();
    try {
      return programs
          .where((p) => p.startTime.isAfter(now))
          .reduce((a, b) => a.startTime.isBefore(b.startTime) ? a : b);
    } catch (_) {}
    return null;
  }
}