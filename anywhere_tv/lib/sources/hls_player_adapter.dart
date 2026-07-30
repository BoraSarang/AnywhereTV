import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/debug_logger.dart';

typedef _MpvSetPropNative = Int32 Function(
  Pointer, Pointer<Utf8>, Pointer<Utf8>,
);
typedef _MpvSetPropDart = int Function(
  Pointer, Pointer<Utf8>, Pointer<Utf8>,
);

class HlsPlayerAdapter {
  final Player player;
  final VideoController controller;
  final DebugLogger _log = DebugLogger.instance;
  double _volume = 100.0;

  HlsPlayerAdapter._({required this.player, required this.controller, required double volume})
      : _volume = volume;

  static Future<HlsPlayerAdapter> create({double volume = 0.5}) async {
    final player = Player();
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    return HlsPlayerAdapter._(player: player, controller: controller, volume: volume * 100.0);
  }

  Future<void> play(String url) async {
    _log.info('HLS', 'play: $url');
    await player.open(Media(url));
    await player.play();
    await _applyVolume();
    _disableMpvSubtitles();
    _log.info('HLS', 'play done, volume=$_volume');
  }

  void _disableMpvSubtitles() {
    try {
      final lib = DynamicLibrary.open('libmpv.so');
      final setProp = lib.lookupFunction<_MpvSetPropNative, _MpvSetPropDart>('mpv_set_property_string');
      player.handle.then((handle) {
        final ctx = Pointer.fromAddress(handle);
        final name = 'sub-visibility'.toNativeUtf8();
        final value = 'no'.toNativeUtf8();
        setProp(ctx, name, value);
        calloc.free(name);
        calloc.free(value);
        _log.info('HLS', 'mpv sub-visibility=no set');
      });
    } catch (e) {
      _log.warn('HLS', 'mpv set sub-visibility failed: $e');
    }
  }

  Future<void> pause() async { await player.pause(); }
  Future<void> resume() async { await player.play(); await _applyVolume(); }
  Future<void> stop() async { await player.stop(); }

  Future<void> setVolume(double volume) async {
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
