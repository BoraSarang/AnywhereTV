import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../widgets/logo_search_dialog.dart';

class EditChannelScreen extends StatefulWidget {
  final Channel channel;
  final List<String> categories;

  const EditChannelScreen({super.key, required this.channel, required this.categories});

  @override
  State<EditChannelScreen> createState() => _EditChannelScreenState();
}

class _EditChannelScreenState extends State<EditChannelScreen> {
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _streamUrlController;
  late final TextEditingController _backupStreamUrlController;
  late final TextEditingController _youtubeHandleController;
  late final TextEditingController _youtubeVideoIdController;
  late String _selectedCategory;
  late String _sourceType;

  @override
  void initState() {
    super.initState();
    final ch = widget.channel;
    _idController = TextEditingController(text: ch.id);
    _nameController = TextEditingController(text: ch.name);
    _logoUrlController = TextEditingController(text: ch.logoUrl);
    _streamUrlController = TextEditingController(text: ch.streamUrl ?? '');
    _backupStreamUrlController =
        TextEditingController(text: ch.backupStreamUrl ?? '');
    _youtubeHandleController = TextEditingController(text: ch.youtubeHandle ?? '');
    _youtubeVideoIdController = TextEditingController(text: ch.youtubeVideoId ?? '');
    _selectedCategory = ch.category;
    _sourceType = ch.sourceType;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _logoUrlController.dispose();
    _streamUrlController.dispose();
    _backupStreamUrlController.dispose();
    _youtubeHandleController.dispose();
    _youtubeVideoIdController.dispose();
    super.dispose();
  }

  void _save() {
    final videoId = _youtubeVideoIdController.text.trim().isEmpty
        ? null
        : _youtubeVideoIdController.text.trim();
    final handle = _youtubeHandleController.text.trim().isEmpty
        ? null
        : _youtubeHandleController.text.trim();
    final (resolver, resolverData) = switch (_sourceType) {
      'youtube' || 'youtube_live' when videoId != null => (
          'youtube',
          {'videoId': videoId}
        ),
      'youtube' || 'youtube_live' when handle != null => (
          'youtube_handle',
          {'handle': handle}
        ),
      'youtube_handle' => (
          'youtube_handle',
          handle != null ? {'handle': handle} : null
        ),
      _ => (null, null),
    };
    final channel = Channel(
      id: _idController.text.trim().isEmpty ? widget.channel.id : _idController.text.trim(),
      name: _nameController.text.trim(),
      logoUrl: _logoUrlController.text.trim(),
      streamUrl: _streamUrlController.text.trim().isEmpty ? null : _streamUrlController.text.trim(),
      backupStreamUrl: _backupStreamUrlController.text.trim().isEmpty
          ? null
          : _backupStreamUrlController.text.trim(),
      youtubeChannelId: widget.channel.youtubeChannelId,
      youtubeVideoId: videoId,
      youtubeHandle: handle,
      category: _selectedCategory,
      sourceType: _sourceType,
      isDefaultFavorite: widget.channel.isDefaultFavorite,
      resolver: resolver,
      resolverData: resolverData,
    );
    Navigator.pop(context, channel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채널 편집'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: '채널 ID (고유 식별자)',
                hintText: '예: kbs1, diggle_6',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: '채널 이름', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _logoUrlController,
              decoration: InputDecoration(
                labelText: '로고 URL',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: '이름으로 로고 검색',
                  onPressed: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('먼저 채널 이름을 입력하세요')),
                      );
                      return;
                    }
                    final result = await showLogoSearchDialog(context, name);
                    if (result != null && mounted) {
                      setState(() => _logoUrlController.text = result);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _sourceType,
              items: ['hls', 'youtube_live', 'youtube', 'youtube_handle']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _sourceType = v!),
              decoration: const InputDecoration(labelText: '소스 유형', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            if (_sourceType == 'hls')
              TextField(
                controller: _streamUrlController,
                decoration: const InputDecoration(labelText: '스트림 URL (.m3u8)', border: OutlineInputBorder()),
              ),
            if (_sourceType != 'hls')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _streamUrlController,
                  decoration: const InputDecoration(
                    labelText: '스트림 URL (선택, HLS 주소)',
                    hintText: '직접 재생 URL이 있으면 입력 (보통 유튜브 채널은 비워 둠)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TextField(
                controller: _backupStreamUrlController,
                decoration: const InputDecoration(
                  labelText: '대체 URL (.m3u8, 선택)',
                  hintText: '기본 스트림 실패 시 사용',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            if (_sourceType == 'youtube_handle')
              TextField(
                controller: _youtubeHandleController,
                decoration: const InputDecoration(labelText: 'YouTube 핸들 (@handle)', border: OutlineInputBorder()),
              ),
            if (_sourceType == 'youtube' || _sourceType == 'youtube_live')
              TextField(
                controller: _youtubeVideoIdController,
                decoration: const InputDecoration(
                  labelText: 'YouTube 비디오 ID',
                  hintText: '예: 8s2pWol8p7M (URL의 v= 값)',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_sourceType == 'youtube' || _sourceType == 'youtube_live')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _youtubeHandleController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube 핸들 (선택, 비디오 ID와 동시 불필요)',
                    hintText: '예: @ytnnews24 — 사용하지 않으면 비워 두세요',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: widget.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
              decoration: const InputDecoration(labelText: '카테고리', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('저장'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
