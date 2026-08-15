import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/github_service.dart';
import '../services/channel_store.dart';

class SettingsScreen extends StatefulWidget {
  final GitHubService github;
  final ChannelStore store;

  const SettingsScreen({super.key, required this.github, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _tokenController;
  late final TextEditingController _gistIdController;
  late final TextEditingController _geminiKeyController;
  bool _autoHealthCheck = false;

  @override
  void initState() {
    super.initState();
    final cfg = widget.github.config;
    _tokenController = TextEditingController(text: cfg.token);
    _gistIdController = TextEditingController(text: cfg.gistId);
    _geminiKeyController = TextEditingController();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _autoHealthCheck = prefs.getBool('auto_health_check') ?? false;
      _geminiKeyController.text = prefs.getString('gemini_api_key') ?? '';
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _gistIdController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  void _save() {
    widget.github.saveConfig(GitHubConfig(
      token: _tokenController.text.trim(),
      gistId: _gistIdController.text.trim(),
    ));
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('auto_health_check', _autoHealthCheck);
      prefs.setString('gemini_api_key', _geminiKeyController.text.trim());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('설정 저장 완료')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = widget.github.config.rawUrl;
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Gist 설정',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('채널 목록은 GitHub Gist에 저장됩니다. '
                '읽기는 토큰 없이 가능하며, 저장하려면 GitHub Personal Access Token이 필요합니다.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'GitHub Personal Access Token',
                hintText: 'ghp_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gistIdController,
              decoration: const InputDecoration(
                labelText: 'Gist ID',
                hintText: '949188737a97773ad5313d9cbd159bff',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText('Raw URL: $rawUrl',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('AI 어시스턴트',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('자연어로 채널 목록을 편집할 수 있습니다. '
                'AI 어시스턴트를 사용하려면 Gemini API 키가 필요합니다.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _geminiKeyController,
              decoration: const InputDecoration(
                labelText: 'Gemini API 키',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Text('헬스체크',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('자동 헬스체크 (5분 간격)'),
              subtitle: const Text('채널 상태를 주기적으로 확인해 라이브 대시보드를 갱신합니다'),
              value: _autoHealthCheck,
              onChanged: (v) => setState(() => _autoHealthCheck = v),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('설정 저장'),
              onPressed: _save,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.cloud_download),
              label: const Text('Gist에서 다운로드'),
              onPressed: () async {
                await widget.store.loadFromRemote();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.store.error ?? 'v${widget.store.version} 불러옴'),
                      backgroundColor: widget.store.error != null ? Colors.red : Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
