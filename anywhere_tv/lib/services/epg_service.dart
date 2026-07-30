import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/epg_program.dart';
import 'debug_logger.dart';

class EpgService {
  static final DebugLogger _log = DebugLogger.instance;

  static Future<List<EpgProgram>> fetchFromUrl(String url, String channelId) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final body = response.body.trim();

      if (body.startsWith('[')) {
        final list = jsonDecode(body) as List;
        return list
            .map((e) => EpgProgram.fromJson(e as Map<String, dynamic>))
            .where((p) => p.channelId == channelId)
            .toList();
      }
      if (body.startsWith('{')) {
        final map = jsonDecode(body) as Map<String, dynamic>;
        final channels = map['channels'] as List? ?? [];
        for (final ch in channels) {
          if ((ch as Map)['id'] == channelId) {
            final programs = ch['programs'] as List? ?? [];
            return programs
                .map((e) => EpgProgram.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
    } catch (e) {
      _log.warn('EPG', 'fetchFromUrl failed: $e');
    }
    return [];
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
