import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'debug_logger.dart';

class BackgroundAudioService {
  static final DebugLogger _log = DebugLogger.instance;
  static bool _initialized = false;
  static bool _running = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        notificationChannelId: 'anywheretv_audio',
        initialNotificationTitle: '어디서나 TV',
        initialNotificationContent: '백그라운드 재생 중',
        foregroundServiceNotificationId: 101,
        onStart: _onStart,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: null,
      ),
    );
  }

  static void _onStart(ServiceInstance service) {
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
    }

    service.on('stop').listen((data) {
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
    });

    service.on('update').listen((data) {
      if (service is AndroidServiceInstance) {
        final channel = data?['channel'] as String? ?? '어디서나 TV';
        service.setForegroundNotificationInfo(
          title: '어디서나 TV',
          content: channel,
        );
        service.setAsForegroundService();
      }
    });
  }

  static Future<void> start() async {
    _running = true;
    final service = FlutterBackgroundService();
    if (!await service.isRunning()) {
      await service.startService();
    }
    _log.system('Background', 'Service started');
  }

  static Future<void> update(String channelName) async {
    if (!_running) return;
    final service = FlutterBackgroundService();
    service.invoke('update', {'channel': channelName});
  }

  static Future<void> stop() async {
    _running = false;
    final service = FlutterBackgroundService();
    service.invoke('stop');
    _log.system('Background', 'Service stopped');
  }
}
