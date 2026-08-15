import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/channel.dart';
import 'package:anywhere_shared/stream_resolution_result.dart';
import 'package:anywhere_shared/stream_resolver.dart';
import '../services/player_service.dart';

class TestPlayScreen extends StatefulWidget {
  final Channel channel;
  const TestPlayScreen({super.key, required this.channel});

  @override
  State<TestPlayScreen> createState() => _TestPlayScreenState();
}

class _TestPlayScreenState extends State<TestPlayScreen> {
  String? _streamUrl;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void dispose() {
    PlayerService.instance.stop();
    super.dispose();
  }

  Future<void> _resolve() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      final ch = widget.channel;
      StreamResolutionResult? result;

      final resolver = ch.resolver ?? switch (ch.sourceType) {
        'youtube' || 'youtube_live' when ch.youtubeVideoId != null => 'youtube',
        'youtube' || 'youtube_live' when ch.youtubeHandle != null => 'youtube_handle',
        _ => null,
      };

      if (resolver != null) {
        final data = <String, dynamic>{};
        if (ch.youtubeVideoId != null) data['videoId'] = ch.youtubeVideoId;
        if (ch.youtubeHandle != null) data['handle'] = ch.youtubeHandle;
        result = await StreamResolver.resolve(resolver: resolver, resolverData: data);
      } else if (ch.streamUrl != null) {
        result = StreamResolutionResult(url: ch.streamUrl!);
      }

      if (result != null) {
        _streamUrl = result.url;
        await PlayerService.instance.play(result.url);
      } else {
        _error = '스트림 URL을 가져올 수 없습니다';
      }
    } catch (e) {
      _error = '오류: $e';
    }
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('테스트: ${widget.channel.name}')),
      body: _resolving
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : PlayerService.instance.controller != null
                  ? Video(controller: PlayerService.instance.controller!)
                  : const Center(child: Text('플레이어 초기화 실패')),
    );
  }
}
