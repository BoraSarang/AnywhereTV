import 'package:http/http.dart' as http;
import 'package:anywhere_shared/debug_logger.dart';

class LogoCandidate {
  final String name;
  final String logoUrl;

  const LogoCandidate({required this.name, required this.logoUrl});
}

class LogoService {
  static final DebugLogger _log = DebugLogger.instance;
  static List<LogoCandidate>? _cachedKr;

  static Future<List<LogoCandidate>> _loadKrList() async {
    if (_cachedKr != null) return _cachedKr!;
    final url = 'https://iptv-org.github.io/iptv/countries/kr.m3u';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      _log.warn('Logo', 'iptv-org 목록 로드 실패: HTTP ${response.statusCode}');
      return [];
    }
    final candidates = <LogoCandidate>[];
    for (final line in response.body.split('\n')) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('#EXTINF')) continue;
      final logoMatch = RegExp(r'tvg-logo="([^"]+)"').firstMatch(trimmed);
      final namePart = trimmed.substring(trimmed.lastIndexOf(',') + 1).trim();
      if (logoMatch == null || namePart.isEmpty) continue;
      candidates.add(
        LogoCandidate(name: namePart, logoUrl: logoMatch.group(1)!),
      );
    }
    _cachedKr = candidates;
    _log.info('Logo', 'iptv-org 한국 목록 캐시: ${candidates.length}개');
    return candidates;
  }

  static Future<List<LogoCandidate>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    try {
      final all = await _loadKrList();
      final scored = all
          .map((c) => (candidate: c, score: _score(c.name, q)))
          .where((e) => e.score > 0)
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));
      return scored.take(10).map((e) => e.candidate).toList();
    } catch (e) {
      _log.error('Logo', '검색 실패: $e');
      return [];
    }
  }

  static int _score(String name, String query) {
    final n = name.toLowerCase();
    if (n == query) return 100;
    if (n.contains(query)) return 50;
    if (query.contains(n)) return 30;
    return 0;
  }
}