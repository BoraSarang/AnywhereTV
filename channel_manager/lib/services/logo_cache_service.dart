import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:anywhere_shared/debug_logger.dart';

class LogoCacheService {
  static final DebugLogger _log = DebugLogger.instance;
  static Directory? _dir;

  static Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final home = Platform.environment['HOME'] ?? '.';
    final dir = Directory(
      '$home/Library/Application Support/AnywhereTVChannelEditor/logos',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _dir = dir;
    return dir;
  }

  static String _fileName(String url) {
    final b64 = base64Url.encode(utf8.encode(url));
    return b64.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
  }

  static Future<String?> cachedPath(String url) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_fileName(url)}');
      return await file.exists() ? file.path : null;
    } catch (e) {
      _log.error('Logo', '캐시 경로 확인 실패: $e');
      return null;
    }
  }

  static Future<bool> fetchAndSave(String url) async {
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      if (resp.statusCode != 200) {
        client.close();
        return false;
      }
      final bytes = await consolidateHttpClientResponseBytes(resp);
      client.close();
      final dir = await _cacheDir();
      await File('${dir.path}/${_fileName(url)}').writeAsBytes(bytes);
      _log.info('Logo', '캐시 저장: ${_fileName(url)}');
      return true;
    } catch (e) {
      _log.error('Logo', '캐시 저장 실패: $url → $e');
      return false;
    }
  }

  static Future<void> precache(List<String> urls) async {
    final todo = urls.toSet().toList();
    if (todo.isEmpty) return;
    _log.info('Logo', '프리캐시 시작: ${todo.length}개');
    var next = 0;
    Future<void> worker() async {
      while (next < todo.length) {
        final url = todo[next++];
        if (await cachedPath(url) != null) continue;
        await fetchAndSave(url);
      }
    }

    await Future.wait([for (var i = 0; i < 3; i++) worker()]);
    _log.info('Logo', '프리캐시 완료');
  }
}