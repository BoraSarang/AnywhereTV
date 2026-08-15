import 'package:flutter_tts/flutter_tts.dart';
import 'package:anywhere_shared/debug_logger.dart';

class TtsService {
  static final TtsService instance = TtsService._();

  TtsService._();

  final FlutterTts _tts = FlutterTts();
  final DebugLogger _log = DebugLogger.instance;
  bool _enabled = false;
  bool _initialized = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      _log.system('TTS', 'Initialized (ko-KR, slow rate)');
    } catch (e) {
      _log.warn('TTS', 'Init failed (플랫폼 미지원 가능): $e');
    }
  }

  void setEnabled(bool value) {
    _enabled = value;
    _log.system('TTS', 'Enabled: $value');
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
      _log.info('TTS', 'Speak: $text');
    } catch (e) {
      _log.error('TTS', 'Speak failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_enabled) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}