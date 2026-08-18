import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anywhere_shared/debug_logger.dart';
import 'package:anywhere_shared/stream_resolver.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../services/channel_store.dart';
import '../services/ai_search_service.dart';
import '../services/youtube_meta_service.dart';
import '../services/player_service.dart';

class AiChannelSearchScreen extends StatefulWidget {
  final ChannelStore store;

  const AiChannelSearchScreen({super.key, required this.store});

  @override
  State<AiChannelSearchScreen> createState() => _AiChannelSearchScreenState();
}

class _AiChannelSearchScreenState extends State<AiChannelSearchScreen>
    with SingleTickerProviderStateMixin {
  static final DebugLogger _log = DebugLogger.instance;
  late final TabController _tabController;
  final _queryController = TextEditingController();
  final _urlController = TextEditingController();
  String? _apiKey;
  List<AiChannelCandidate> _results = [];
  bool _loading = false;
  String? _error;
  String? _testingIndex;

  ChannelStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadApiKey();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    _urlController.dispose();
    PlayerService.instance.stop();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiKey = prefs.getString('gemini_api_key'));
  }

  Future<void> _search({required bool isSite}) async {
    final query = _queryController.text.trim();
    final siteUrl = _urlController.text.trim();
    if (isSite) {
      final uri = Uri.tryParse(siteUrl);
      if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
        setState(() => _error = 'E-MAN-URL-1005');
        return;
      }
      if (siteUrl.isEmpty) {
        setState(() => _error = 'E-MAN-URL-1005');
        return;
      }
    } else if (query.isEmpty) {
      return;
    }
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() => _error = 'E-MAN-AUTH-1001');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
    });
    final (results, status) = await AiSearchService.searchChannels(
      apiKey: _apiKey!,
      query: isSite ? siteUrl : query,
      siteUrl: isSite ? siteUrl : null,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (status == 429 || status == 403) {
        _error = 'E-MAN-AI-1005';
        _results = [];
      } else {
        _results = results ?? [];
        if (results == null) _error = 'E-MAN-AI-1003';
      }
    });
  }

  Future<String?> _resolveUrl(String url) async {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final videoId = RegExp(r'(?:v=|youtu\.be/|/shorts/)([a-zA-Z0-9_-]{11})')
          .firstMatch(url)
          ?.group(1);
      if (videoId != null) {
        final result = await StreamResolver.resolve(
          resolver: 'youtube',
          resolverData: {'videoId': videoId},
        );
        return result?.url;
      }
      final handle = RegExp(r'youtube\.com/@([a-zA-Z0-9_-]+)')
          .firstMatch(url)
          ?.group(1);
      if (handle != null) {
        final result = await StreamResolver.resolve(
          resolver: 'youtube_handle',
          resolverData: {'handle': handle},
        );
        return result?.url;
      }
    }
    return url;
  }

  Future<void> _testPlay(int index) async {
    final candidate = _results[index];
    final url = candidate.channelUrl ?? '';
    if (url.isEmpty) return;
    setState(() => _testingIndex = '$index');
    final resolved = await _resolveUrl(url);
    if (resolved != null) {
      _log.info('AI', '테스트 재생: ${candidate.name}');
      await PlayerService.instance.play(resolved);
    } else {
      _log.warn('AI', '테스트 실패: ${candidate.name}');
    }
    if (mounted) setState(() => _testingIndex = null);
  }

  Future<void> _addCandidate(AiChannelCandidate candidate) async {
    final url = candidate.channelUrl ?? '';
    final isYoutube = url.contains('youtube.com') || url.contains('youtu.be');
    final videoId = isYoutube
        ? RegExp(r'(?:v=|youtu\.be/|/shorts/)([a-zA-Z0-9_-]{11})')
            .firstMatch(url)
            ?.group(1)
        : null;
    final handle = isYoutube
        ? (RegExp(r'youtube\.com/@([a-zA-Z0-9_-]+)').firstMatch(url)?.group(1) ??
            YoutubeMetaService.extractHandle(url))
        : null;

    String? channelId;
    String? avatarUrl = candidate.logoUrl;
    if (isYoutube && handle != null) {
      final meta = await YoutubeMetaService.fetch('https://www.youtube.com/@$handle');
      if (meta != null) {
        channelId = meta.channelId;
        avatarUrl = meta.avatarUrl ?? avatarUrl;
      } else {
        _log.warn('AI', '유튜브 메타 파싱 실패: $handle');
      }
    }

    final String sourceType;
    String? streamUrl;
    String? resolver;
    Map<String, dynamic>? resolverData;
    if (isYoutube && videoId != null) {
      sourceType = 'youtube';
      resolver = 'youtube';
      resolverData = {'videoId': videoId};
    } else if (isYoutube && handle != null) {
      sourceType = 'youtube_handle';
      resolver = 'youtube_handle';
      resolverData = {'handle': handle};
    } else {
      streamUrl = url;
      if (url.contains('.mpd')) {
        sourceType = 'dash';
      } else if (RegExp(r'\.(mp3|aac|ogg|m4a)(\?|$)').hasMatch(url)) {
        sourceType = 'audio';
      } else {
        sourceType = 'hls';
      }
    }

    final dupe = _store.channels.any((ch) =>
        (ch.youtubeHandle != null && handle != null &&
            ch.youtubeHandle!.toLowerCase() == handle.toLowerCase()) ||
        (ch.youtubeVideoId != null && videoId != null &&
            ch.youtubeVideoId == videoId) ||
        (ch.streamUrl != null && streamUrl != null && ch.streamUrl == streamUrl) ||
        (ch.name.toLowerCase() == candidate.name.toLowerCase()));
    if (dupe) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('중복 감지'),
          content: const Text('같은 채널이 이미 목록에 있습니다. 그래도 추가할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('그래도 추가'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    final category = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('카테고리 선택'),
        children: [
          for (final cat in _store.categories)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, cat),
              child: Text(cat),
            ),
        ],
      ),
    );
    if (category == null || !mounted) return;

    final baseId = candidate.name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final cleanId = baseId.isNotEmpty
        ? baseId
        : 'channel_${DateTime.now().millisecondsSinceEpoch % 100000}';
    final existingIds = _store.channels.map((c) => c.id).toSet();
    var id = cleanId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$cleanId-$suffix';
      suffix++;
    }

    final channel = Channel(
      id: id,
      name: candidate.name,
      logoUrl: avatarUrl ?? '',
      streamUrl: streamUrl,
      youtubeChannelId: channelId,
      youtubeVideoId: videoId,
      youtubeHandle: handle,
      category: category,
      sourceType: sourceType,
      resolver: resolver,
      resolverData: resolverData,
    );
    _store.addChannel(channel);
    _log.info('AI', '채널 추가(추천): ${candidate.name} ($category) — 총 ${_store.channels.length}개');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채널 추가됨: ${candidate.name} ($category)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채널 추천 (AI)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '자연어 추천', icon: Icon(Icons.auto_awesome)),
            Tab(text: '사이트 조사', icon: Icon(Icons.public)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 64,
              child: TabBarView(
                controller: _tabController,
                children: [
                  TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      labelText: '원하는 채널 (예: "경제 뉴스 24시간 채널")',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.travel_explore),
                        tooltip: 'AI 검색 (비용 발생)',
                        onPressed: _loading ? null : () => _search(isSite: false),
                      ),
                    ),
                    onSubmitted: (_) => _loading ? null : _search(isSite: false),
                  ),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: '사이트 URL (예: https://tv.example.com)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.public),
                        tooltip: 'AI 조사 (비용 발생)',
                        onPressed: _loading ? null : () => _search(isSite: true),
                      ),
                    ),
                    onSubmitted: (_) => _loading ? null : _search(isSite: true),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _error == 'E-MAN-AUTH-1001'
                        ? Icons.key_off
                        : _error == 'E-MAN-URL-1005'
                            ? Icons.link_off
                            : Icons.error_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error == 'E-MAN-AUTH-1001'
                          ? '설정에서 Gemini API 키를 입력해 주세요 (E-MAN-AUTH-1001)'
                          : _error == 'E-MAN-AI-1003'
                              ? 'AI 검색 결과를 해석하지 못했습니다. 다시 시도해 주세요 (E-MAN-AI-1003)'
                              : _error == 'E-MAN-AI-1005'
                                  ? 'Gemini API 할당량을 초과했습니다. 잠시 후 다시 시도하거나 AI Studio에서 플랜을 확인해 주세요 (E-MAN-AI-1005)'
                                  : _error == 'E-MAN-URL-1005'
                                      ? '올바른 사이트 URL(http/https)을 입력해 주세요 (E-MAN-URL-1005)'
                                      : _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('웹 검색 중... (최대 30초)',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'AI 검색으로 채널을 찾아보세요.\n후보를 테스트 재생해 보고 추가할 수 있습니다.\n\n(검색 1회당 소액 비용 발생)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final c = _results[index];
                          final url = c.channelUrl ?? '';
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  if (c.logoUrl != null && c.logoUrl!.isNotEmpty)
                                    Image.network(
                                      c.logoUrl!,
                                      width: 40,
                                      height: 40,
                                      errorBuilder: (_, _, _) => const Icon(
                                          Icons.live_tv, size: 40),
                                    )
                                  else
                                    const Icon(Icons.live_tv, size: 40),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(c.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        if (c.description.isNotEmpty)
                                          Text(c.description,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        if (url.isNotEmpty)
                                          Text(url,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blueGrey)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: _testingIndex == '$index'
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2))
                                        : const Icon(Icons.play_circle_outline),
                                    tooltip: '테스트 재생',
                                    onPressed:
                                        url.isEmpty ? null : () => _testPlay(index),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () => _addCandidate(c),
                                    child: const Text('추가'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (PlayerService.instance.controller != null)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Video(controller: PlayerService.instance.controller!),
              ),
            ),
        ],
      ),
    );
  }
}
