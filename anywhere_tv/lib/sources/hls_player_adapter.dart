import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/debug_logger.dart';

class HlsPlayerAdapter {
  final Player player;
  final VideoController controller;
  final DebugLogger _log = DebugLogger.instance;
  double _volume = 100.0; // media_kit/mpv scale: 0-100

  HlsPlayerAdapter._({required this.player, required this.controller, required double volume})
      : _volume = volume;

  static Future<HlsPlayerAdapter> create({double volume = 0.5}) async {
    final player = Player();
    final controller = VideoController(player);
    // volume: 0.0-1.0 → mpv scale 0-100
    return HlsPlayerAdapter._(player: player, controller: controller, volume: volume * 100.0);
  }

  Future<void> play(String url) async {
    _log.info('HLS', 'play: $url');
    await player.open(Media(url));
    await player.play();
    await _applyVolume();
    _log.info('HLS', 'play done, volume=$_volume');
  }

  Future<void> pause() async { await player.pause(); }
  Future<void> resume() async { await player.play(); await _applyVolume(); }
  Future<void> stop() async { await player.stop(); }

  Future<void> setVolume(double volume) async {
    // volume: 0.0-1.0 → mpv scale 0-100
    _volume = volume * 100.0;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    try {
      await player.setVolume(_volume);
    } catch (e) {
      _log.error('HLS', 'setVolume failed: $e');
    }
  }

  Future<void> dispose() async {
    _log.info('HLS', 'disposing');
    try {
      await player.stop();
    } catch (_) {}
    try {
      await player.dispose();
    } catch (_) {}
    _log.info('HLS', 'disposed');
  }
}
