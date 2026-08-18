import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../widgets/logo_search_dialog.dart';
import 'package:anywhere_shared/stream_resolver.dart';
import '../services/player_service.dart';

class AddChannelScreen extends StatefulWidget {
  final List<String> categories;
  final List<Channel> existingChannels;
  const AddChannelScreen({
    super.key,
    required this.categories,
    this.existingChannels = const [],
  });

  @override
  State<AddChannelScreen> createState() => _AddChannelScreenState();
}

class _AddChannelScreenState extends State<AddChannelScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _logoUrlController = TextEditingController();
  String? _selectedCategory;
  String? _sourceType;
  String? _resolvedUrl;
  String? _resolvedTitle;
  String? _youtubeHandle;
  String? _youtubeVideoId;
  String? _youtubeChannelId;
  bool _resolving = false;
  String? _error;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _idController.dispose();
    _logoUrlController.dispose();
    PlayerService.instance.stop();
    super.dispose();
  }

  String _autoId(String name) {
    final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    final cleaned = base
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    if (cleaned.isNotEmpty) return cleaned;
    return 'channel_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  String? _detectSourceType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      if (url.contains('/@') || RegExp(r'youtube\.com/(c/|channel/|@)').hasMatch(url)) {
        return 'youtube_handle';
      }
      return 'youtube';
    }
    if (url.contains('.mpd')) return 'dash';
    if (RegExp(r'\.(mp3|aac|ogg|m4a)(\?|$)').hasMatch(url)) return 'audio';
    return 'hls';
  }

  String? _extractVideoId(String url) {
    final match = RegExp(r'(?:v=|youtu\.be/|/shorts/)([a-zA-Z0-9_-]{11})').firstMatch(url);
    return match?.group(1);
  }

  String? _extractHandle(String url) {
    final match = RegExp(r'youtube\.com/@([a-zA-Z0-9_-]+)').firstMatch(url);
    return match?.group(1);
  }

  Future<void> _resolve() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _resolving = true;
      _error = null;
      _resolvedUrl = null;
      _resolvedTitle = null;
      _youtubeHandle = null;
      _youtubeVideoId = null;
      _sourceType = _detectSourceType(url);
    });

    try {
      if (_sourceType == 'youtube') {
        final videoId = _extractVideoId(url);
        if (videoId == null) {
          setState(() { _error = '올바른 YouTube URL이 아닙니다'; _resolving = false; });
          return;
        }
        _youtubeVideoId = videoId;
        final result = await StreamResolver.resolve(
          resolver: 'youtube',
          resolverData: {'videoId': videoId},
        );
        if (result != null) {
          _resolvedUrl = result.url;
          _resolvedTitle = result.title;
          _nameController.text = result.title ?? '';
        } else {
          _error = '스트림을 가져올 수 없습니다';
        }
      } else if (_sourceType == 'youtube_handle') {
        final handle = _extractHandle(url);
        if (handle == null) {
          setState(() { _error = '올바른 YouTube 핸들 URL이 아닙니다'; _resolving = false; });
          return;
        }
        _youtubeHandle = handle;
        final result = await StreamResolver.resolve(
          resolver: 'youtube_handle',
          resolverData: {'handle': handle},
        );
        if (result != null) {
          _resolvedUrl = result.url;
          _resolvedTitle = result.title;
          _nameController.text = result.title ?? '';
        } else {
          _error = 'YouTube 핸들을 가져올 수 없습니다';
        }
      } else {
        _resolvedUrl = url;
        _nameController.text = Uri.tryParse(url)?.pathSegments.last.replaceAll('.m3u8', '') ?? '새 채널';
      }
    } catch (e) {
      _error = '오류: $e';
    }

    if (mounted) setState(() => _resolving = false);
  }

  Future<void> _testPlay() async {
    if (_resolvedUrl == null) return;
    setState(() => _playing = true);
    await PlayerService.instance.play(_resolvedUrl!);
    setState(() => _playing = false);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('채널 이름을 입력하세요')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리를 선택하세요')),
      );
      return;
    }

    final rawUrl = _urlController.text.trim();
    if (_sourceType == null && rawUrl.isNotEmpty) {
      _sourceType = _detectSourceType(rawUrl);
      if (_sourceType == 'youtube') {
        _youtubeVideoId ??= _extractVideoId(rawUrl);
      } else if (_sourceType == 'youtube_handle') {
        _youtubeHandle ??= _extractHandle(rawUrl);
      }
    }

    final dupeMessages = <String>[];
    final lowerName = name.toLowerCase();
    for (final ch in widget.existingChannels) {
      if (ch.id == _idController.text.trim()) {
        dupeMessages.add('채널 ID "${ch.id}"가 이미 사용 중입니다 (${ch.name})');
      } else if (ch.name.toLowerCase() == lowerName) {
        dupeMessages.add('같은 이름 "${ch.name}"의 채널이 이미 있습니다');
      } else if (ch.youtubeVideoId != null &&
          _youtubeVideoId != null &&
          ch.youtubeVideoId == _youtubeVideoId) {
        dupeMessages.add('같은 YouTube 동영상(${ch.youtubeVideoId})이 "${ch.name}"에 있습니다');
      } else if (ch.youtubeHandle != null &&
          _youtubeHandle != null &&
          ch.youtubeHandle!.toLowerCase() == _youtubeHandle!.toLowerCase()) {
        dupeMessages.add('같은 YouTube 핸들(${ch.youtubeHandle})이 "${ch.name}"에 있습니다');
      } else if (ch.streamUrl != null && _resolvedUrl != null && ch.streamUrl == _resolvedUrl) {
        dupeMessages.add('같은 스트림 URL이 "${ch.name}"에 있습니다');
      }
    }

    if (dupeMessages.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('중복 감지 (${dupeMessages.length}건)'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in dupeMessages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(m)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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

    final baseId = _idController.text.trim().isEmpty
        ? _autoId(name)
        : _idController.text.trim();
    final existingIds = widget.existingChannels.map((c) => c.id).toSet();
    var id = baseId;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$baseId-$suffix';
      suffix++;
    }

    final channel = Channel(
      id: id,
      name: name,
      logoUrl: _logoUrlController.text.trim(),
      streamUrl: (_sourceType == 'hls' || _sourceType == 'dash' || _sourceType == 'audio')
          ? _resolvedUrl
          : null,
      youtubeChannelId: _youtubeChannelId,
      youtubeVideoId: _youtubeVideoId,
      youtubeHandle: _youtubeHandle,
      category: _selectedCategory!,
      sourceType: _sourceType ?? 'hls',
      resolver: _sourceType == 'hls'
          ? null
          : (_sourceType == 'youtube_handle' ? 'youtube_handle' : 'youtube'),
      resolverData: _sourceType == 'hls'
          ? null
          : (_sourceType == 'youtube_handle'
              ? (_youtubeHandle != null ? {'handle': _youtubeHandle} : null)
              : (_youtubeVideoId != null ? {'videoId': _youtubeVideoId} : null)),
    );
    Navigator.pop(context, channel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('채널 추가')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '① URL 붙여넣기 (YouTube 링크 또는 .m3u8 HLS 주소)\n'
              '② 검색 아이콘(🔍) 누르면 채널 정보 자동 해석\n'
              '③ 이름·카테고리 확인 후 저장',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL (YouTube / HLS .m3u8)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _resolving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _resolve,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_resolving)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  '해석 중... (유튜브 응답 대기, 최대 20초)',
                  style: TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ),
            if (_sourceType != null)
              Text('유형: $_sourceType', style: const TextStyle(color: Colors.grey)),
            if (_resolvedTitle != null)
              Text('제목: $_resolvedTitle', style: const TextStyle(color: Colors.green)),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {
                _idController.text = _autoId(_nameController.text.trim());
              }),
              decoration: const InputDecoration(
                labelText: '채널 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '채널 ID (자동 생성, 수정 가능)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _logoUrlController,
              decoration: InputDecoration(
                labelText: '로고 URL (선택)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '이름으로 로고 검색',
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('먼저 채널 이름을 입력하세요')),
                      );
                      return;
                    }
                    final result = await showLogoSearchDialog(context, name);
                    if (result != null && mounted) {
                      setState(() {
                        _logoUrlController.text = result.logoUrl;
                        if (result.name != null && result.name!.isNotEmpty) {
                          _nameController.text = result.name!;
                          _idController.text = _autoId(result.name!);
                        }
                        if (result.handle != null && result.handle!.isNotEmpty) {
                          _youtubeHandle = result.handle;
                          _youtubeChannelId = result.channelId;
                          _sourceType = 'youtube_handle';
                          _urlController.text =
                              'https://www.youtube.com/${result.handle}';
                          _resolvedUrl = null;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              decoration: const InputDecoration(
                labelText: '카테고리',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('테스트 재생'),
                    onPressed: _resolvedUrl != null ? _testPlay : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('저장'),
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (PlayerService.instance.controller != null)
              SizedBox(
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Video(controller: PlayerService.instance.controller!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
