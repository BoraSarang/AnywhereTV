import 'dart:io';
import 'package:anywhere_shared/debug_logger.dart';

class BackupService {
  static const int _maxBackups = 20;
  static final DebugLogger _log = DebugLogger.instance;

  static Future<Directory> _backupDir() async {
    final home = Platform.environment['HOME'] ?? '.';
    final dir = Directory(
      '$home/Library/Application Support/AnywhereTVChannelEditor/backups',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _stamp(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  static Future<String?> saveBackup({
    required String content,
    required int version,
  }) async {
    try {
      final dir = await _backupDir();
      final file = File(
          '${dir.path}/channels_v${version}_${_stamp(DateTime.now())}.json');
      await file.writeAsString(content);
      await _prune(dir);
      _log.info('Backup', '백업 저장: ${file.path}');
      return file.path;
    } catch (e) {
      _log.error('Backup', '백업 실패: $e');
      return null;
    }
  }

  static Future<List<File>> listBackups() async {
    try {
      final dir = await _backupDir();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (e) {
      _log.error('Backup', '백업 목록 조회 실패: $e');
      return [];
    }
  }

  static Future<void> _prune(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'))
        .toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    for (final f in files.skip(_maxBackups)) {
      await f.delete();
    }
  }
}