import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'channel_list_screen.dart';
import '../models/channel.dart';
import '../models/user_state.dart';
import '../repositories/channel_repository.dart';
import '../services/debug_logger.dart';
import '../services/user_state_service.dart';
import '../models/stream_resolution_result.dart';
import '../sources/hls_player_adapter.dart';
import '../resolvers/stream_resolver.dart';

class PlayerScreen extends StatefulWidget {
  final ChannelRepository channelRepo;
  final UserStateService userStateService;
  final UserState userState;

  const PlayerScreen({
    super.key,
    required this.channelRepo,
    required this.userStateService,
    required this.userState,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late List<Channel> _favoriteChannels;
  bool _showOverlay = true;

  HlsPlayerAdapter? _hlsAdapter;
  String? _loadError;

  bool _isPlaying = true;
  double _volume = 1.0;
  bool _loading = false;
  String _preferredResolution = 'auto';
  bool _needsRestore = false;
  String? _currentTitle;

  List<String> get _categoryOrder {
    final order = <String>[];
    for (final ch in widget.channelRepo.channels) {
      if (!order.contains(ch.category)) order.add(ch.category);
    }
    return order;
  }

  void _sortByCategoryOrder() {
    final order = _categoryOrder;
    _favoriteChannels.sort((a, b) {
      final ai = order.indexOf(a.category);
      final bi = order.indexOf(b.category);
      return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
    });
  }

  int get _targetHeight {
    switch (_preferredResolution) {
      case '360': return 360;
      case '480': return 480;
      case '720': return 720;
      case '1080': return 1080;
      default: return 360; // auto = 360 (안정적)
    }
  }

  final DebugLogger _log = DebugLogger.instance;

  Channel? get currentChannel =>
      _favoriteChannels.isNotEmpty ? _favoriteChannels[_currentIndex] : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _volume = widget.userState.lastVolume > 0 ? widget.userState.lastVolume : 1.0;
    _preferredResolution = widget.userState.preferredResolution;
    _initFavorites();
    _initPlayerForCurrentChannel();
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _overlayTimer?.cancel();
    try {
      if (_hlsAdapter != null) {
        _hlsAdapter!.stop();
        _hlsAdapter!.dispose();
      }
    } catch (_) {}
    _hlsAdapter = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _needsRestore) {
      _needsRestore = false;
      if (mounted) _initPlayerForCurrentChannel();
    } else if (state == AppLifecycleState.paused) {
      _needsRestore = true;
      try {
        _hlsAdapter?.stop();
        _hlsAdapter?.dispose();
      } catch (_) {}
      _hlsAdapter = null;
    }
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _prevChannel();
      return true;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _nextChannel();
      return true;
    }
    return false;
  }

  void _initFavorites() {
    final saved = widget.userState.favoriteChannelIds;
    final all = widget.channelRepo.channels;
    if (saved.isNotEmpty) {
      _favoriteChannels = all.where((c) => saved.contains(c.id)).toList();
    } else {
      _favoriteChannels = widget.channelRepo.defaultFavorites.toList();
    }
    _sortByCategoryOrder();
    if (_favoriteChannels.isEmpty) {
      _favoriteChannels = List.from(all);
    }
    final lastId = widget.userState.lastWatchedChannelId;
    if (lastId != null) {
      final idx = _favoriteChannels.indexWhere((c) => c.id == lastId);
      if (idx >= 0) _currentIndex = idx;
    }
    if (_currentIndex >= _favoriteChannels.length) _currentIndex = 0;
    _log.info('Player', 'Favorites: ${_favoriteChannels.length} channels');
  }

  Future<void> _initPlayerForCurrentChannel() async {
    if (_favoriteChannels.isEmpty) return;
    final channel = _favoriteChannels[_currentIndex];
    _log.info('Player', '▶ ${channel.name}');
    if (!mounted) return;

    setState(() { _loading = true; _loadError = null; _isPlaying = true; });
    await _disposeCurrentPlayer();

    try {
      StreamResolutionResult? result;
      if (channel.sourceType == 'youtube_live') {
        if (channel.youtubeHandle != null && channel.youtubeHandle!.isNotEmpty) {
          _log.info('Player', 'Resolving YouTube via handle: ${channel.youtubeHandle}');
          result = await StreamResolver.resolve(
            resolver: 'youtube_handle',
            resolverData: {'handle': channel.youtubeHandle},
            targetHeight: _targetHeight,
          );
        }
        if (result == null && channel.youtubeVideoId != null && channel.youtubeVideoId!.isNotEmpty) {
          _log.info('Player', 'Fallback to videoId: ${channel.youtubeVideoId}');
          result = await StreamResolver.resolve(
            resolver: 'youtube',
            resolverData: {'videoId': channel.youtubeVideoId},
            targetHeight: _targetHeight,
          );
        }
        if (result == null) {
          _log.warn('Player', 'YouTube resolution returned null');
          _loadError = '라이브 스트림을 불러올 수 없습니다';
        }
      } else {
        String? url = channel.streamUrl;
        if (url == null || url.isEmpty) {
          _log.info('Player', 'Resolving ${channel.name}...');
          result = await _resolveStreamUrl(channel);
        } else {
          result = StreamResolutionResult(url: url);
        }
      }

      if (result != null && result.url.isNotEmpty) {
        _log.info('Player', 'Stream URL: ${result.url.length > 80 ? '${result.url.substring(0, 80)}...' : result.url}');
        _currentTitle = result.title;
        _hlsAdapter = await HlsPlayerAdapter.create(volume: _volume);
        await _hlsAdapter!.play(result.url);
        _log.info('Player', 'Player started');
      } else if (_loadError == null) {
        _log.error('Player', 'No stream URL for ${channel.name}');
        _loadError = '스트림 주소를 확인할 수 없습니다';
      }
    } catch (e, s) {
      _log.error('Player', 'Init failed: $e\n$s');
      _loadError = '스트림을 불러올 수 없습니다';
      await _disposeCurrentPlayer();
    }

    if (mounted) setState(() { _loading = false; });
  }

  Future<StreamResolutionResult?> _resolveStreamUrl(Channel channel) async {
    if (channel.resolver == null || channel.resolver!.isEmpty) return null;
    return await StreamResolver.resolve(
      resolver: channel.resolver!,
      resolverData: channel.resolverData,
      targetHeight: _targetHeight,
    );
  }

  Future<void> _disposeCurrentPlayer() async {
    try {
      if (_hlsAdapter != null) {
        await _hlsAdapter!.dispose();
      }
    } catch (e) {
      _log.error('Player', 'Dispose error: $e');
    }
    _hlsAdapter = null;
  }

  Timer? _overlayTimer;

  void _switchChannel(int newIndex) {
    if (newIndex < 0 || newIndex >= _favoriteChannels.length) return;
    final name = _favoriteChannels[newIndex].name;
    _log.info('Player', 'Switch to: $name');
    if (mounted) {
      setState(() { _currentIndex = newIndex; _showOverlay = true; _loadError = null; _currentTitle = null; });
    }
    _resetOverlayTimer();
    _initPlayerForCurrentChannel();
    widget.userStateService.setLastChannel(_favoriteChannels[_currentIndex].id);
  }

  void _nextChannel() {
    _log.info('Player', 'nextChannel: current=$_currentIndex total=${_favoriteChannels.length}');
    _switchChannel((_currentIndex + 1) % _favoriteChannels.length);
  }
  void _prevChannel() {
    _log.info('Player', 'prevChannel: current=$_currentIndex total=${_favoriteChannels.length}');
    _switchChannel((_currentIndex - 1 + _favoriteChannels.length) % _favoriteChannels.length);
  }

  void _resetOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showOverlay = false);
    });
  }

  void _toggleOverlay() {
    if (!mounted) return;
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) _resetOverlayTimer();
  }

  void _onOverlayTap() {
    if (_showOverlay) _resetOverlayTimer();
  }

  void _togglePlayPause() {
    if (_hlsAdapter == null) return;
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _hlsAdapter!.resume();
    } else {
      _hlsAdapter!.pause();
    }
    _resetOverlayTimer();
  }

  void _setVolume(double v) {
    if (!mounted) return;
    setState(() => _volume = v);
    if (_hlsAdapter != null) {
      _hlsAdapter!.setVolume(v);
    }
    widget.userStateService.setVolume(v);
    _resetOverlayTimer();
  }

  void _toggleFullscreen() {
    const MethodChannel('com.okstart.anywheretv/window').invokeMethod('toggleFullscreen');
  }

  void _openChannelList() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChannelListScreen(
          channelRepo: widget.channelRepo,
          currentChannelId: currentChannel?.id,
        ),
      ),
    );
    if (result is Map && result['channelId'] is String) {
      final id = result['channelId'] as String;
      int idx = _favoriteChannels.indexWhere((c) => c.id == id);
      if (idx < 0) {
        final channel = widget.channelRepo.channels.firstWhere((c) => c.id == id);
        setState(() {
          _favoriteChannels.add(channel);
          _sortByCategoryOrder();
          idx = _favoriteChannels.indexWhere((c) => c.id == id);
        });
      }
      _switchChannel(idx);
    }
  }

  Future<void> _openSettings() async {
    final prevRes = _preferredResolution;
    final result = await Navigator.of(context).pushNamed<String>(
      '/settings',
    );
    if (!mounted) return;
    _initFavorites();
    if (_currentIndex >= _favoriteChannels.length) _currentIndex = 0;
    setState(() {});
    if (result != null && result != prevRes) {
      _preferredResolution = result;
      widget.userStateService.setResolution(_preferredResolution);
      _log.system('Player', 'Resolution changed: $prevRes → $_preferredResolution');
      _initPlayerForCurrentChannel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_favoriteChannels.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('등록된 채널이 없습니다.', style: TextStyle(color: Colors.white70, fontSize: 18))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildPlayerWidget(),
    );
  }

  Widget _buildPlayerWidget() {
    final channel = currentChannel;
    if (channel == null) return const SizedBox();
    if (_loadError != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white38, size: 48),
                  const SizedBox(height: 16),
                  Text(_loadError!, style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => _initPlayerForCurrentChannel(),
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    label: const Text('재시도', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
          _topBar(),
          if (_favoriteChannels.length > 1) ...[
            _navButtonLeft(),
            _navButtonRight(),
          ],
        ],
      );
    }
    if (_hlsAdapter == null || _loading) {
      return Stack(
        children: [
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          if (_showOverlay && _favoriteChannels.length > 1) ...[
            _navButtonLeft(),
            _navButtonRight(),
          ],
        ],
      );
    }
    return Stack(
      children: [
        Video(controller: _hlsAdapter!.controller, controls: null),
        if (!_showOverlay)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleOverlay,
              behavior: HitTestBehavior.translucent,
            ),
          ),
        if (_showOverlay) ...[
          _overlayContent(),
          if (_favoriteChannels.length > 1) ...[
            _navButtonLeft(),
            _navButtonRight(),
          ],
        ],
      ],
    );
  }

  Widget _topBar() {
    final channel = currentChannel;
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xBB000000), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            if (channel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(channel.category, style: const TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.none)),
              ),
            const Spacer(),
            GestureDetector(
              onTap: _openChannelList,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.list, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _openSettings,
              child: Container(
                width: 44, height: 44,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.settings, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButtonLeft() {
    return Positioned(
      left: 8, top: 0, bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: _prevChannel,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _navButtonRight() {
    return Positioned(
      right: 8, top: 0, bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: _nextChannel,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.skip_next, color: Colors.white, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _overlayContent() {
    final channel = currentChannel;
    return GestureDetector(
      onTap: _onOverlayTap,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            _topBar(),
            if (channel != null)
              Positioned(
                left: 0, right: 0, top: 0, bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        channel.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                      if (_currentTitle != null && _currentTitle!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _currentTitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 16,
                              decoration: TextDecoration.none,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 0, right: 0, bottom: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xBB000000), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.volume_up, color: Colors.white70, size: 20),
                    Expanded(
                      child: Slider(
                        value: _volume,
                        min: 0,
                        max: 1,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white30,
                        thumbColor: Colors.white,
                        onChanged: _setVolume,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleFullscreen,
                      child: Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
