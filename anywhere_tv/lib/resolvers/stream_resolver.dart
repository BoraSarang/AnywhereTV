import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stream_resolution_result.dart';
import '../services/debug_logger.dart';

/// HLS master manifest에서 최저 해상도 variant URL 추출
Future<String?> _filterHlsLowestQuality(String masterUrl, {int targetHeight = 360}) async {
  final log = DebugLogger.instance;
  try {
    final response = await http.get(Uri.parse(masterUrl)).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return masterUrl;
    final body = response.body;
    if (!body.contains('#EXTM3U')) return masterUrl;

    final lines = body.split('\n');
    String? bestUrl;
    int bestHeight = 99999;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (!line.contains('#EXT-X-STREAM-INF:')) continue;
      final resMatch = RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
      int? h;
      if (resMatch != null) h = int.tryParse(resMatch.group(2)!);
      if (h == null) continue;
      if (h < targetHeight || h >= bestHeight) continue;
      if (i + 1 >= lines.length) continue;
      final urlLine = lines[i + 1].trim();
      if (urlLine.isEmpty || urlLine.startsWith('#')) continue;
      bestHeight = h;
      bestUrl = Uri.parse(masterUrl).resolve(urlLine).toString();
    }
    if (bestUrl != null) {
      log.info('HLS', 'selected ${bestHeight}p variant');
      return bestUrl;
    }
    return masterUrl;
  } catch (e) {
    log.warn('HLS', 'filter failed: $e');
    return masterUrl;
  }
}

class StreamResolver {
  static final DebugLogger _log = DebugLogger.instance;

  static Future<StreamResolutionResult?> resolve({
    required String resolver,
    Map<String, dynamic>? resolverData,
    int targetHeight = 360,
  }) async {
    _log.info('Resolver', '$resolver $resolverData');
    StreamResolutionResult? result;
    switch (resolver) {
      case 'kbs':
        final url = await _resolveKbs(resolverData);
        if (url != null) result = StreamResolutionResult(url: url);
      case 'sbs':
        final url = await _resolveSbs(resolverData);
        if (url != null) result = StreamResolutionResult(url: url);
      case 'mbc':
        final url = await _resolveMbc(resolverData);
        if (url != null) result = StreamResolutionResult(url: url);
      case 'youtube':
        result = await _resolveYoutube(resolverData);
      case 'youtube_handle':
        result = await _resolveYoutubeHandle(resolverData);
      default:
        _log.warn('Resolver', 'Unknown resolver: $resolver');
    }
    if (result != null) {
      final filtered = await _filterHlsLowestQuality(result.url, targetHeight: targetHeight);
      if (filtered != null && filtered != result.url) {
        result = StreamResolutionResult(url: filtered, title: result.title);
      }
    }
    return result;
  }

  // ── YouTube (InnerTube API, androidSdkless client) ──
  static Future<StreamResolutionResult?> _resolveYoutube(Map<String, dynamic>? data) async {
    final videoId = data?['videoId'] as String?;
    if (videoId == null || videoId.isEmpty) {
      _log.error('Youtube', 'No videoId in resolverData');
      return null;
    }
    _log.apiCall('Youtube', 'GET', 'videoId=$videoId');

    final body = jsonEncode({
      'context': {
        'client': {
          'clientName': 'ANDROID',
          'clientVersion': '20.10.38',
          'userAgent': 'com.google.android.youtube/20.10.38 (Linux; U; Android 11) gzip',
          'hl': 'en',
          'timeZone': 'UTC',
          'utcOffsetMinutes': 0,
          'osName': 'Android',
          'osVersion': '11',
        },
      },
      'videoId': videoId,
    });

    try {
      final response = await http.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/player?prettyPrint=false'),
        headers: {
          'Content-Type': 'application/json',
          'X-YouTube-Client-Name': 'ANDROID',
          'X-YouTube-Client-Version': '20.10.38',
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      _log.apiResponse('Youtube', response.statusCode, '');
      if (response.statusCode != 200) {
        _log.error('Youtube', 'HTTP ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body);
      final videoDetails = json['videoDetails'] as Map<String, dynamic>?;
      final title = videoDetails?['title'] as String?;

      final streamingData = json['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) {
        _log.error('Youtube', 'No streamingData in response');
        return null;
      }

      final hlsUrl = streamingData['hlsManifestUrl'] as String?;
      if (hlsUrl != null && hlsUrl.isNotEmpty) {
        _log.info('Youtube', 'HLS URL via InnerTube');
        return StreamResolutionResult(url: hlsUrl, title: title);
      }

      _log.error('Youtube', 'No hlsManifestUrl in streamingData');
      return null;
    } catch (e) {
      _log.error('Youtube', 'InnerTube API failed: $e');
      return null;
    }
  }

  // ── YouTube Handle (채널 핸들 → live page → videoId → InnerTube) ──
  static Future<StreamResolutionResult?> _resolveYoutubeHandle(Map<String, dynamic>? data) async {
    final handle = data?['handle'] as String?;
    if (handle == null || handle.isEmpty) {
      _log.error('Youtube', 'No handle in resolverData');
      return null;
    }
    final liveUrl = 'https://www.youtube.com/$handle/live';
    final liveUri = Uri.parse(liveUrl);
    _log.apiCall('Youtube', 'GET', liveUrl);

    String? videoId;
    try {
      final response = await http.get(liveUri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
          'Accept-Language': 'ko-KR,ko;q=0.9,en;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));
      _log.apiResponse('Youtube', response.statusCode, '$liveUri');
      if (response.statusCode != 200) {
        _log.error('Youtube', 'HTTP ${response.statusCode} for $liveUri');
        return null;
      }

      final body = response.body;
      // ytInitialPlayerResponse에서 videoId 추출 (brace-depth 파싱)
      final initStart = body.indexOf('ytInitialPlayerResponse = ');
      if (initStart >= 0) {
        final braceStart = body.indexOf('{', initStart);
        if (braceStart >= 0) {
          int depth = 0;
          for (int i = braceStart; i < body.length; i++) {
            if (body[i] == '{') { depth++; continue; }
            if (body[i] == '}') { depth--; if (depth == 0) {
              try {
                final json = jsonDecode(body.substring(braceStart, i + 1));
                videoId = json['currentVideoEndpoint']?['watchEndpoint']?['videoId'] as String?;
                videoId ??= json['videoDetails']?['videoId'] as String?;
              } catch (_) {}
              break;
            }}
          }
        }
      }
      // fallback: ytInitialData
      if (videoId == null) {
        final dataStart = body.indexOf('ytInitialData = ');
        if (dataStart >= 0) {
          final braceStart = body.indexOf('{', dataStart);
          if (braceStart >= 0) {
            int depth = 0;
            for (int i = braceStart; i < body.length; i++) {
              if (body[i] == '{') { depth++; }
              else if (body[i] == '}') { depth--; if (depth == 0) {
                try {
                  final json = jsonDecode(body.substring(braceStart, i + 1));
                  final rs = json['contents']?['twoColumnWatchNextResults']?['results']?['results']?['contents'] as List?;
                  if (rs != null) {
                    for (final c in rs) {
                      final v = c?['videoPrimaryInfoRenderer']?['title']?['runs']?[0]?['navigationEndpoint']?['watchEndpoint']?['videoId'] as String?;
                      if (v != null) { videoId = v; break; }
                    }
                  }
                } catch (_) {}
                break;
              }}
            }
          }
        }
      }
      // fallback: HTML watch?v= 패턴
      if (videoId == null) {
        final watchMatch = RegExp(r'watch\?v=([a-zA-Z0-9_-]{11})').firstMatch(body);
        if (watchMatch != null) videoId = watchMatch.group(1);
      }
    } catch (e) {
      _log.error('Youtube', 'Live page fetch failed: $e');
      return null;
    }

    if (videoId == null || videoId.isEmpty) {
      _log.error('Youtube', 'Could not extract videoId from live page');
      return null;
    }

    _log.info('Youtube', 'Extracted videoId=$videoId from $handle');
    return await _resolveYoutube({'videoId': videoId});
  }

  // ── KBS ──
  static Future<String?> _resolveKbs(Map<String, dynamic>? data) async {
    final channelCode = data?['channelCode'] as String? ?? '11';
    _log.apiCall('KBS', 'GET', 'channel_code=$channelCode');

    try {
      final url = 'https://cfpwwwapi.kbs.co.kr/api/v1/landing/live/channel_code/$channelCode';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      _log.apiResponse('KBS', response.statusCode, url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['channel_item'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          final item = items[0] as Map<String, dynamic>;
          final serviceUrl = item['service_url'] as String?;
          if (serviceUrl != null && serviceUrl.isNotEmpty) {
            _log.info('KBS', 'Stream URL via landing API');
            return serviceUrl;
          }
        }
        _log.warn('KBS', 'No channel_item in response');
      } else {
        _log.error('KBS', 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      _log.error('KBS', 'Landing API failed: $e');
    }

    try {
      final url2 = 'https://myk.kbs.co.kr/broadcast_live/channel_master_items_json';
      final response2 = await http.post(
        Uri.parse(url2),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Origin': 'https://myk.kbs.co.kr',
          'Referer': 'https://myk.kbs.co.kr/',
        },
        body: 'src_channel_type=&os_type=pc&pk_token=',
      ).timeout(const Duration(seconds: 10));
      _log.apiResponse('KBS', response2.statusCode, 'myk broadcast');
      if (response2.statusCode == 200) {
        final json2 = jsonDecode(response2.body);
        final episodes = json2['live_episode_items'] as List<dynamic>?;
        if (episodes != null) {
          for (final ep in episodes) {
            final code = ep['channel_code']?['value']?.toString();
            if (code == channelCode) {
              final info = ep['normal_stream_info'];
              if (info != null) {
                final serviceUrl = info['service_url'] as String?;
                if (serviceUrl != null && serviceUrl.isNotEmpty) {
                  _log.info('KBS', 'Stream URL via myk API');
                  return serviceUrl;
                }
              }
            }
          }
        }
      }
    } catch (e) {
      _log.error('KBS', 'myk API failed: $e');
    }

    _log.error('KBS', 'All KBS resolvers failed for channel $channelCode');
    return null;
  }

  // ── SBS ──
  static Future<String?> _resolveSbs(Map<String, dynamic>? data) async {
    final channelId = data?['channelId'] as String? ?? 'S05';
    _log.apiCall('SBS', 'GET', 'channelId=$channelId');

    try {
      final url = 'https://apis.sbs.co.kr/play-api/1.0/onair/channel/$channelId'
          '?protocol=hls&v_type=2&platform=pcweb&ssl=N&rscuse=&jwt-token=&sbsmain=';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Referer': 'https://www.sbs.co.kr/'},
      ).timeout(const Duration(seconds: 10));
      _log.apiResponse('SBS', response.statusCode, url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final onair = json['onair'] as Map<String, dynamic>?;
        if (onair != null) {
          final source = onair['source'] as Map<String, dynamic>?;
          if (source != null) {
            final ms = source['mediasource'] as Map<String, dynamic>?;
            if (ms != null) {
              final mediaUrl = ms['mediaurl'] as String?;
              if (mediaUrl != null && mediaUrl.isNotEmpty) {
                _log.info('SBS', 'Stream URL from mediasource');
                return mediaUrl;
              }
            }
            final list = source['mediasourcelist'] as List<dynamic>?;
            if (list != null && list.isNotEmpty) {
              for (final item in list.reversed) {
                final m = item as Map<String, dynamic>;
                final mediaUrl = m['mediaurl'] as String?;
                if (mediaUrl != null && mediaUrl.isNotEmpty) {
                  _log.info('SBS', 'Stream URL from mediasourcelist');
                  return mediaUrl;
                }
              }
            }
          }
        }
        _log.warn('SBS', 'Unexpected response: ${response.body.length} chars');
      } else {
        _log.error('SBS', 'HTTP ${response.statusCode}');
      }
    } catch (e) {
      _log.error('SBS', 'API failed: $e');
    }

    _log.error('SBS', 'All SBS resolvers failed for $channelId');
    return null;
  }

  // ── MBC ──
  static Future<String?> _resolveMbc(Map<String, dynamic>? data) async {
    _log.apiCall('MBC', 'GET', 'mediaapi.imbc.com');

    String? previewUrl;
    for (final onairtype in [5, 6, 3, 4, 1]) {
      try {
        final apiUrl = 'https://mediaapi.imbc.com/Player/OnAirURLUtil?type=PC&onairtype=$onairtype';
        final response = await http.get(
          Uri.parse(apiUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'https://onair.imbc.com/',
            'Origin': 'https://onair.imbc.com',
          },
        ).timeout(const Duration(seconds: 10));
        _log.apiResponse('MBC', response.statusCode, 'onairtype=$onairtype');

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final msg = json['Msg'] as String?;
          if (msg == 'OK') {
            final mediaInfo = json['MediaInfo'] as Map<String, dynamic>?;
            if (mediaInfo != null) {
              var mediaUrl = mediaInfo['MediaURL'] as String?;
              if (mediaUrl != null) {
                if (mediaUrl.startsWith('//')) mediaUrl = 'https:$mediaUrl';
                if (!mediaUrl.contains('preview') && !mediaUrl.contains('3min')) {
                  _log.info('MBC', 'Full stream URL (onairtype=$onairtype)');
                  return mediaUrl;
                }
                previewUrl ??= mediaUrl;
              }
            }
          }
        }
      } catch (e) {
        _log.error('MBC', 'onairtype=$onairtype failed: $e');
      }
    }
    if (previewUrl != null) {
      _log.warn('MBC', 'Only preview URL available (may be geo-blocked)');
      return previewUrl;
    }

    try {
      final url = 'https://onair.imbc.com/';
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'},
      ).timeout(const Duration(seconds: 10));
      _log.apiResponse('MBC', response.statusCode, url);

      if (response.statusCode == 200) {
        final body = response.body;
        final reg = RegExp("mediaUrl\\s*[=:]\\s*[\"']([^\"']+\\.m3u8[^\"']*)[\"']");
        final match = reg.firstMatch(body);
        if (match != null) {
          _log.info('MBC', 'Stream URL from page mediaUrl regex');
          return match.group(1);
        }
      }
    } catch (e) {
      _log.error('MBC', 'Page scrape failed: $e');
    }

    for (final u in [
      'https://mbctv.gscdn.mbc.co.kr/mbctv/mbctv_hd.m3u8',
      'https://mbctv.gscdn.mbc.co.kr/mbctv/mbctv.m3u8',
    ]) {
      try {
        final r = await http.head(Uri.parse(u)).timeout(const Duration(seconds: 5));
        _log.apiResponse('MBC', r.statusCode, u);
        if (r.statusCode == 200) {
          _log.info('MBC', 'Stream URL direct: $u');
          return u;
        }
      } catch (_) {}
    }

    _log.error('MBC', 'All MBC resolvers failed');
    return null;
  }
}
