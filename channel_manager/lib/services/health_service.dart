import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:anywhere_shared/debug_logger.dart';
import 'package:anywhere_shared/stream_resolver.dart';
import '../models/channel.dart';

enum HealthStatus { ok, failed, unknown }

class ChannelHealth {
  final HealthStatus status;
  final String message;
  final int latencyMs;

  const ChannelHealth({
    required this.status,
    required this.message,
    required this.latencyMs,
  });
}

class HealthService extends ChangeNotifier {
  static const int _concurrency = 4;
  static const Duration _timeout = Duration(seconds: 20);

  final DebugLogger _log = DebugLogger.instance;
  final Map<String, ChannelHealth> _results = {};
  bool _checking = false;

  bool get checking => _checking;
  Map<String, ChannelHealth> get results => Map.unmodifiable(_results);

  HealthStatus statusFor(String channelId) =>
      _results[channelId]?.status ?? HealthStatus.unknown;

  int get okCount => _results.values.where((r) => r.status == HealthStatus.ok).length;
  int get failedCount => _results.values.where((r) => r.status == HealthStatus.failed).length;
  int get unknownCount => _results.values.where((r) => r.status == HealthStatus.unknown).length;

  List<MapEntry<Channel, ChannelHealth>> failedFor(List<Channel> channels) {
    return channels
        .where((c) => _results[c.id]?.status == HealthStatus.failed)
        .map((c) => MapEntry(c, _results[c.id]!))
        .toList();
  }

  void invalidate(List<String> channelIds) {
    final ids = channelIds.toSet();
    final removed = _results.keys.where((k) => !ids.contains(k)).toList();
    if (removed.isEmpty) return;
    removed.forEach(_results.remove);
    notifyListeners();
  }

  Future<void> checkAll(List<Channel> channels) async {
    if (_checking || channels.isEmpty) return;
    _checking = true;
    notifyListeners();

    _log.action('Health', 'checkAll 시작: ${channels.length}개 채널');
    for (var i = 0; i < channels.length; i += _concurrency) {
      final batch = channels.skip(i).take(_concurrency).toList();
      await Future.wait(batch.map(checkChannel));
    }
    _checking = false;
    _log.action('Health', 'checkAll 완료: ok=$okCount failed=$failedCount unknown=$unknownCount');
    notifyListeners();
  }

  Future<ChannelHealth> checkChannel(Channel channel) async {
    final start = DateTime.now();
    _log.action('Health', '검사: ${channel.name} (${channel.sourceType})');
    ChannelHealth result;
    try {
      result = await _checkInternal(channel);
      final latency = DateTime.now().difference(start).inMilliseconds;
      result = ChannelHealth(
        status: result.status,
        message: result.message,
        latencyMs: latency,
      );
    } catch (e) {
      result = ChannelHealth(
        status: HealthStatus.failed,
        message: '$e',
        latencyMs: DateTime.now().difference(start).inMilliseconds,
      );
    }
    _results[channel.id] = result;
    _log.info('Health',
        '${channel.name}: ${result.status.name} (${result.latencyMs}ms) ${result.message}');
    notifyListeners();
    return result;
  }

  Future<ChannelHealth> _checkInternal(Channel channel) async {
    final isYoutube = channel.youtubeVideoId != null ||
        channel.youtubeHandle != null ||
        channel.resolver == 'youtube' ||
        channel.resolver == 'youtube_handle';
    final resolver = channel.resolver ??
        (channel.youtubeVideoId != null
            ? 'youtube'
            : channel.youtubeHandle != null ? 'youtube_handle' : null);
    final resolverData = channel.resolverData ??
        (channel.youtubeVideoId != null
            ? {'videoId': channel.youtubeVideoId}
            : channel.youtubeHandle != null
                ? {'handle': channel.youtubeHandle}
                : const {});
    if (resolver != null && resolver.isNotEmpty && resolver != 'hls') {
      final resolved = await StreamResolver.resolve(
        resolver: resolver,
        resolverData: resolverData,
        filterQuality: false,
      ).timeout(_timeout);
      if (resolved != null) {
        if (resolved.url.contains('.m3u8')) {
          final manifest = await _checkHls(resolved.url);
          if (manifest.status == HealthStatus.ok) {
            return isYoutube
                ? ChannelHealth(
                    status: HealthStatus.ok,
                    message: '라이브 스트림 + HLS 매니페스트 응답',
                    latencyMs: 0,
                  )
                : const ChannelHealth(
                    status: HealthStatus.ok,
                    message: '스트림 획득 + HLS 매니페스트 응답',
                    latencyMs: 0,
                  );
          }
          return ChannelHealth(
            status: HealthStatus.failed,
            message: '스트림 URL은 획득했지만 매니페스트 응답 없음: ${manifest.message}',
            latencyMs: 0,
          );
        }
        return const ChannelHealth(
          status: HealthStatus.ok,
          message: '스트림 획득 성공',
          latencyMs: 0,
        );
      }
      return isYoutube
          ? const ChannelHealth(
              status: HealthStatus.failed,
              message: '스트림을 가져올 수 없음 (방송 중 아님)',
              latencyMs: 0,
            )
          : const ChannelHealth(
              status: HealthStatus.failed,
              message: '스트림을 가져올 수 없음',
              latencyMs: 0,
            );
    }

    final url = channel.streamUrl;
    if (url == null || url.isEmpty) {
      return const ChannelHealth(
        status: HealthStatus.unknown,
        message: '스트림 소스 없음',
        latencyMs: 0,
      );
    }
    final primary = await _checkHls(url);
    if (primary.status == HealthStatus.failed &&
        channel.backupStreamUrl != null &&
        channel.backupStreamUrl!.isNotEmpty) {
      final backup = await _checkHls(channel.backupStreamUrl!);
      if (backup.status == HealthStatus.ok) {
        return const ChannelHealth(
          status: HealthStatus.ok,
          message: '기본 실패, 대체 URL 정상',
          latencyMs: 0,
        );
      }
      return ChannelHealth(
        status: HealthStatus.failed,
        message: '기본/대체 모두 실패: ${primary.message}',
        latencyMs: 0,
      );
    }
    return primary;
  }

  Future<ChannelHealth> _checkHls(String url) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36';
      final streamed = await client.send(request).timeout(_timeout);
      if (streamed.statusCode != 200) {
        return ChannelHealth(
          status: HealthStatus.failed,
          message: 'HTTP ${streamed.statusCode}',
          latencyMs: 0,
        );
      }
      final first = await streamed.stream.first.timeout(_timeout);
      final head = String.fromCharCodes(first);
      if (head.contains('#EXTM3U')) {
        return const ChannelHealth(
          status: HealthStatus.ok,
          message: 'HLS 매니페스트 응답',
          latencyMs: 0,
        );
      }
      return const ChannelHealth(
        status: HealthStatus.ok,
        message: 'HTTP 200 응답',
        latencyMs: 0,
      );
    } catch (e) {
      return ChannelHealth(
        status: HealthStatus.failed,
        message: '$e',
        latencyMs: 0,
      );
    } finally {
      client.close();
    }
  }
}