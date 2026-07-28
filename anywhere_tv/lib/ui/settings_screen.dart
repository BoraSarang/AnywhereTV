import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/channel_repository.dart';
import '../services/debug_logger.dart';

class SettingsScreen extends StatefulWidget {
  final ChannelRepository channelRepo;
  final String currentResolution;
  final ValueChanged<String> onResolutionChanged;

  const SettingsScreen({
    super.key,
    required this.channelRepo,
    required this.currentResolution,
    required this.onResolutionChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DebugLogger _log = DebugLogger.instance;
  bool _checking = false;
  String? _updateResult;

  static const resolutions = ['자동', '360p', '480p', '720p', '1080p'];
  static const resolutionMap = {
    '자동': 'auto',
    '360p': '360',
    '480p': '480',
    '720p': '720',
    '1080p': '1080',
  };

  late String _selectedLabel;

  @override
  void initState() {
    super.initState();
    _selectedLabel = _labelFor(widget.currentResolution);
  }

  String _labelFor(String res) {
    return resolutions.firstWhere(
      (l) => resolutionMap[l] == res,
      orElse: () => '자동',
    );
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _checking = true;
      _updateResult = null;
    });
    final updated = await widget.channelRepo.checkForUpdates();
    setState(() {
      _checking = false;
      _updateResult = updated ? '채널 목록이 업데이트되었습니다.' : '최신 상태입니다.';
    });
    _log.system('Settings', 'Update check: ${updated ? "updated" : "up-to-date"}, v${widget.channelRepo.currentVersion}');
  }

  int _channelCount() => widget.channelRepo.channels.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('설정', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(resolutionMap[_selectedLabel]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('채널 업데이트'),
          _infoTile('현재 버전', 'v${widget.channelRepo.currentVersion}'),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _checking ? null : _checkUpdate,
              icon: _checking
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh, color: Colors.white),
              label: Text(_checking ? '확인 중...' : '업데이트 확인'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF533483),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_updateResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _updateResult!,
                style: TextStyle(
                  color: _updateResult!.contains('업데이트') ? const Color(0xFF8CE99A) : Colors.white70,
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 32),
          _sectionHeader('화질'),
          ...resolutions.map((label) => RadioListTile<String>(
            title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
            value: label,
            groupValue: _selectedLabel,
            activeColor: const Color(0xFF533483),
            toggleable: false,
            onChanged: (val) {
              if (val == null) return;
              setState(() => _selectedLabel = val);
              widget.onResolutionChanged(resolutionMap[val]!);
            },
          )),

          const SizedBox(height: 32),
          _sectionHeader('앱 정보'),
          _infoTile('앱 이름', '어디서나 TV'),
          _infoTile('앱 버전', 'v1.0.0'),
          _infoTile('제작자', 'BoRaSaRang'),
          _linkTile('문의', 'leeborasarang@gmail.com', 'mailto:leeborasarang@gmail.com'),
          _linkTile('후원하기', '☕ Buy Me a Coffee', 'https://buymeacoffee.com/borasarang'),
          _infoTile('채널 수', '${_channelCount()}개'),
          _infoTile('데이터 버전', 'v${widget.channelRepo.currentVersion}'),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF533483),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _linkTile(String label, String display, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              display,
              style: const TextStyle(color: Color(0xFF74C0FC), fontSize: 14, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
