import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'services/github_service.dart';
import 'services/channel_store.dart';
import 'screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const ChannelManagerApp());
}

class ChannelManagerApp extends StatefulWidget {
  const ChannelManagerApp({super.key});

  @override
  State<ChannelManagerApp> createState() => _ChannelManagerAppState();
}

class _ChannelManagerAppState extends State<ChannelManagerApp> {
  final GitHubService _github = GitHubService();
  late final ChannelStore _store;

  @override
  void initState() {
    super.initState();
    _store = ChannelStore(_github);
    _init();
  }

  Future<void> _init() async {
    await _github.loadConfig();
    final cfg = _github.config;
    if (cfg.token.isNotEmpty || cfg.gistId.isNotEmpty) {
      _store.hasConfig;
      await _store.loadFromRemote();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '채널 관리자',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: MainScreen(store: _store, github: _github),
    );
  }
}
