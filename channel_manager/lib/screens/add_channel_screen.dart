import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import '../models/stream_resolution_result.dart';
import '../services/stream_resolver.dart';
import '../services/player_service.dart';

class AddChannelScreen extends StatefulWidget {
  final List<String> categories;
  const AddChannelScreen({super.key, required this.categories});

  @override
  State<AddChannelScreen> createState() => _AddChannelScreenState();
}

class _AddChannelScreenState extends State<AddChannelScreen> {
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  String? _selectedCategory;
  String? _sourceType;
  String? _resolvedUrl;
  String? _resolvedTitle;
  String? _youtubeHandle;
  String? _youtubeVideoId;
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
    _logoUrlController.dispose();
    PlayerService.instance.stop();
    super.dispose();
  }

  String? _detectSourceType(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      if (url.contains('/@') || RegExp(r'youtube\.com/(c/|channel/|@)').hasMatch(url)) {
        return 'youtube_handle';
      }
      return 'youtube';
    }
    if (url.contains('.m3u8')) return 'hls';
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

  void _save() {
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

    final channel = Channel(
      id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_'),
      name: name,
      logoUrl: _logoUrlController.text.trim(),
      streamUrl: _sourceType == 'hls' ? _resolvedUrl : null,
      youtubeVideoId: _youtubeVideoId,
      youtubeHandle: _youtubeHandle,
      category: _selectedCategory!,
      sourceType: _sourceType ?? 'hls',
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
            if (_sourceType != null)
              Text('유형: $_sourceType', style: const TextStyle(color: Colors.grey)),
            if (_resolvedTitle != null)
              Text('제목: $_resolvedTitle', style: const TextStyle(color: Colors.green)),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '채널 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _logoUrlController,
              decoration: const InputDecoration(
                labelText: '로고 URL (선택)',
                border: OutlineInputBorder(),
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
