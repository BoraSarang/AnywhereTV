import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final cfg = widget.github.config;
    _tokenController = TextEditingController(text: cfg.token);
    _gistIdController = TextEditingController(text: cfg.gistId);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _gistIdController.dispose();
    super.dispose();
  }

  void _save() {
    widget.github.saveConfig(GitHubConfig(
      token: _tokenController.text.trim(),
      gistId: _gistIdController.text.trim(),
    ));
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
