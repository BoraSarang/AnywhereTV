import 'package:flutter/foundation.dart';

enum LogLevel { action, apiReq, apiRes, info, warn, error, system }

class LogEntry {
  final int id;
  final DateTime timestamp;
  final LogLevel level;
  final String platform;
  final String category;
  final String message;
  final String? meta;

  LogEntry({
    required this.id,
    required this.level,
    required this.platform,
    required this.category,
    required this.message,
    this.meta,
  }) : timestamp = DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelLabel {
    switch (level) {
      case LogLevel.action: return 'ACTION';
      case LogLevel.apiReq: return 'API→';
      case LogLevel.apiRes: return 'API←';
      case LogLevel.info: return 'INFO';
      case LogLevel.warn: return 'WARN';
      case LogLevel.error: return 'ERROR';
      case LogLevel.system: return 'SYSTEM';
    }
  }

  String get formatted {
    final metaStr = meta != null ? ' | meta=$meta' : '';
    return '[$formattedTime] [$levelLabel] [$platform] [$category] $message$metaStr';
  }
}

class DebugLogger {
  DebugLogger._();

  static final DebugLogger _instance = DebugLogger._();
  static DebugLogger get instance => _instance;

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 5000;
  bool _isDebug = true;
  final ValueNotifier<int> _changeNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get changeNotifier => _changeNotifier;
  int _nextId = 0;

  String _platform = '';
  DateTime? _autoScrollPausedUntil;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  bool get isAutoScrollPaused =>
      _autoScrollPausedUntil != null && DateTime.now().isBefore(_autoScrollPausedUntil!);

  void pauseAutoScroll({Duration duration = const Duration(seconds: 2)}) {
    _autoScrollPausedUntil = DateTime.now().add(duration);
  }

  String get platform {
    if (_platform.isEmpty) {
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        _platform = 'macos';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        _platform = 'ios';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        _platform = 'android';
      } else {
        _platform = 'web';
      }
    }
    return _platform;
  }

  void setReleaseMode() {
    _isDebug = false;
    _logs.clear();
  }

  String _maskSecrets(dynamic obj) {
    if (obj == null) return '';
    String str = obj.toString();
    if (str.contains('token') || str.contains('password') ||
        str.contains('secret') || str.contains('keystore') ||
        str.contains('authorization')) {
      return '***MASKED***';
    }
    if (str.length > 500) {
      str = '${str.substring(0, 500)}...(truncated)';
    }
    return str;
  }

  void _add(LogLevel level, String category, String message, dynamic meta) {
    if (!_isDebug) return;
    final entry = LogEntry(
      id: _nextId++,
      level: level,
      platform: platform,
      category: category,
      message: message,
      meta: _maskSecrets(meta),
    );
    _logs.add(entry);
    debugPrint(entry.formatted);
    if (_logs.length > _maxLogs) _logs.removeAt(0);
    _changeNotifier.value++;
  }

  void action(String category, String message, {dynamic meta}) => _add(LogLevel.action, category, message, meta);
  void apiCall(String category, String method, String url, {dynamic meta}) => _add(LogLevel.apiReq, category, '$method $url', meta);
  void apiResponse(String category, int status, String url, {dynamic meta, int? latencyMs}) {
    final lat = latencyMs != null ? ' latency=${latencyMs}ms' : '';
    _add(LogLevel.apiRes, category, '$status $url$lat', meta);
  }
  void info(String category, String message, {dynamic meta}) => _add(LogLevel.info, category, message, meta);
  void warn(String category, String message, {dynamic meta}) => _add(LogLevel.warn, category, message, meta);
  void error(String category, String message, {dynamic meta}) => _add(LogLevel.error, category, message, meta);
  void system(String category, String message, {dynamic meta}) => _add(LogLevel.system, category, message, meta);

  void clear() {
    _logs.clear();
    _autoScrollPausedUntil = null;
  }

  String formatForAgent([List<LogEntry>? entries]) {
    final list = entries ?? _logs;
    final body = list.map((e) => e.formatted).join('\n');
    return '```\n$body\n```';
  }
}
