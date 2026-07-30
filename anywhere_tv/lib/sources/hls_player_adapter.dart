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
  _MpvSetPropDart? _mpvSetProp;

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

  void _initMpvApi() {
    if (_mpvSetProp != null) return;
    try {
      final lib = DynamicLibrary.open('libmpv.so');
      _mpvSetProp = lib.lookupFunction<_MpvSetPropNative, _MpvSetPropDart>('mpv_set_property_string');
    } catch (e) {
      _log.warn('HLS', 'mpv API init failed: $e');
    }
  }

  Future<void> _mpvSet(String name, String value) async {
    final fn = _mpvSetProp;
    if (fn == null) {
      _log.warn('HLS', 'mpv API not initialized');
      return;
    }
    try {
      final handle = await player.handle;
      final ptr = handle;
      _log.info('HLS', 'mpv handle=$ptr');
      final ctx = Pointer.fromAddress(ptr);
      final n = name.toNativeUtf8();
      final v = value.toNativeUtf8();
      final result = fn(ctx, n, v);
      calloc.free(n);
      calloc.free(v);
      _log.info('HLS', 'mpv set $name=$value -> $result');
    } catch (e) {
      _log.warn('HLS', 'mpv set $name=$value failed: $e');
    }
  }

  Future<void> play(String url) async {
    _log.info('HLS', 'play: $url');
    _initMpvApi();
    await Future.wait([
      _mpvSet('sub-visibility', 'no'),
      _mpvSet('subs-fallback', 'no'),
      _mpvSet('subs-with-matching-audio', 'no'),
      _mpvSet('sub-scale', '0'),
    ]);
    try {
      await player.setSubtitleTrack(SubtitleTrack.no());
    } catch (_) {}
    await player.open(Media(url));
    await player.play();
    await _applyVolume();
    try {
      await player.setSubtitleTrack(SubtitleTrack.no());
    } catch (_) {}
    _log.info('HLS', 'play done, volume=$_volume');
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
