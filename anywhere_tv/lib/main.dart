import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:dpad/dpad.dart';
import 'models/user_state.dart';
import 'repositories/channel_repository.dart';
import 'package:anywhere_shared/debug_logger.dart';
import 'services/user_state_service.dart';
import 'services/background_service.dart';
import 'services/error_messages.dart';
import 'services/tts_service.dart';
import 'ui/debug_panel.dart';
import 'ui/player_screen.dart';
import 'ui/settings_screen.dart';

final ValueNotifier<bool> mediaKitReady = ValueNotifier<bool>(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundAudioService.init();
  TtsService.instance.init();
  runApp(const AnywhereTvApp());
  await Future.delayed(Duration.zero);
  MediaKit.ensureInitialized();
  debugPrint('[main] MediaKit initialized');
  mediaKitReady.value = true;
}

class AnywhereTvApp extends StatefulWidget {
  const AnywhereTvApp({super.key});

  @override
  State<AnywhereTvApp> createState() => _AnywhereTvAppState();
}

class _AnywhereTvAppState extends State<AnywhereTvApp> {
  final ChannelRepository _channelRepo = ChannelRepository();
  final UserStateService _userStateService = UserStateService();
  UserState _userState = const UserState();
  bool _initialized = false;
  bool _mkReady = false;

  bool get _ready => _initialized && _mkReady;

  @override
  void initState() {
    super.initState();
    mediaKitReady.addListener(_onMediaKitReady);
    _init();
  }

  @override
  void dispose() {
    mediaKitReady.removeListener(_onMediaKitReady);
    super.dispose();
  }

  void _onMediaKitReady() {
    if (mediaKitReady.value && mounted) {
      setState(() => _mkReady = true);
    }
  }

  Future<void> _init() async {
    final log = DebugLogger.instance;
    log.system('App', 'Initializing...');
    try {
      await ErrorMessages.init();
      await _userStateService.init();
      log.system('App', 'UserStateService done');
      await _channelRepo.init();
      _channelRepo.onChannelsUpdated = () {
        if (mounted) setState(() {});
      };
      log.system('App', 'ChannelRepo done');
    } catch (e) {
      log.error('App', 'Init error: $e');
    }
    setState(() {
      _userState = _userStateService.load();
      TtsService.instance.setEnabled(_userState.ttsEnabled);
      if (_userState.favoriteChannelIds.isEmpty) {
        final defaults = _channelRepo.defaultFavorites.map((c) => c.id).toList();
        _userState = _userState.copyWith(favoriteChannelIds: defaults);
        _userStateService.save(_userState);
        log.system('App', 'Set default favorites: $defaults');
      }
      _initialized = true;
    });
    log.system('App', 'Init done');
  }

  @override
  Widget build(BuildContext context) {
    final body = _ready ? _buildPlayer() : const _SplashScreen();
    return MaterialApp(
      title: '어디서나 TV',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF533483),
          secondary: Color(0xFF0F3460),
          surface: Color(0xFF16213E),
        ),
      ),
      home: kReleaseMode ? body : DebugOverlay(child: body),
      builder: Dpad.wrap(),
      onGenerateRoute: (routeSettings) {
        if (routeSettings.name == '/settings') {
          return MaterialPageRoute<String>(
            builder: (_) => SettingsScreen(
              channelRepo: _channelRepo,
              currentResolution: _userState.preferredResolution,
              onResolutionChanged: (res) {
                _updateResolution(res);
              },
              ttsEnabled: _userState.ttsEnabled,
              onTtsChanged: (value) {
                _userState = _userState.copyWith(ttsEnabled: value);
                _userStateService.setTtsEnabled(value);
                TtsService.instance.setEnabled(value);
                DebugLogger.instance.system('App', 'TTS toggled: $value');
              },
              broadcastAlertsEnabled: _userState.broadcastAlertsEnabled,
              onBroadcastAlertsChanged: (value) {
                _userState = _userState.copyWith(broadcastAlertsEnabled: value);
                _userStateService.setBroadcastAlertsEnabled(value);
                DebugLogger.instance.system('App', 'Broadcast alerts toggled: $value');
              },
              epgServerUrl: _userState.epgServerUrl,
              onEpgServerUrlChanged: (value) {
                _userState = _userState.copyWith(epgServerUrl: value.isEmpty ? null : value);
                _userStateService.setEpgServerUrl(value);
                DebugLogger.instance.system('App', 'EPG server URL changed');
              },
            ),
          );
        }
        return null;
      },
    );
  }

  void _updateResolution(String res) {
    _userState = _userState.copyWith(preferredResolution: res);
    _userStateService.setResolution(res);
    DebugLogger.instance.system('App', 'Resolution set to $res');
  }

  Widget _buildPlayer() {
    return PlayerScreen(
      channelRepo: _channelRepo,
      userStateService: _userStateService,
      userState: _userState,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tv, color: Color(0xFF533483), size: 64),
            SizedBox(height: 16),
            Text(
              '어디서나 TV',
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF533483)),
          ],
        ),
      ),
    );
  }
}
