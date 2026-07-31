import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class PlayerService {
  PlayerService._();

  static final PlayerService instance = PlayerService._();

  Player? _player;
  VideoController? _controller;

  Player? get player => _player;
  VideoController? get controller => _controller;

  Future<void> ensureInitialized() async {
    if (_player != null) return;
    _player = Player();
    _controller = VideoController(
      _player!,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
  }

  Future<void> play(String url) async {
    await ensureInitialized();
    await _player!.open(Media(url));
    await _player!.play();
  }

  Future<void> stop() async {
    if (_player == null) return;
    await _player!.stop();
  }

  Future<void> dispose() async {
    if (_player == null) return;
    await _player!.stop();
    await _player!.dispose();
    _player = null;
    _controller = null;
  }
}
