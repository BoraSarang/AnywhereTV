import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/m3u_service.dart';

class M3uImportScreen extends StatefulWidget {
  final List<M3uEntry> entries;
  final List<String> categories;
  final List<Channel> existingChannels;

  const M3uImportScreen({
    super.key,
    required this.entries,
    required this.categories,
    required this.existingChannels,
  });

  @override
  State<M3uImportScreen> createState() => _M3uImportScreenState();
}

class _M3uImportScreenState extends State<M3uImportScreen> {
  final Set<String> _selected = {};
  final Map<String, String> _categoryOverride = {};
  String _defaultCategory = '';

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _defaultCategory = widget.categories.first;
    }
    _selected.addAll(widget.entries.map((e) => e.url));
  }

  String _categoryFor(M3uEntry entry) {
    if (_categoryOverride.containsKey(entry.url)) {
      return _categoryOverride[entry.url]!;
    }
    return entry.groupTitle.isNotEmpty ? entry.groupTitle : _defaultCategory;
  }

  String _autoId(String name, Set<String> existingIds) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final root = base.isEmpty
        ? 'channel_${DateTime.now().millisecondsSinceEpoch % 100000}'
        : base;
    var id = root;
    var suffix = 2;
    while (existingIds.contains(id)) {
      id = '$root-$suffix';
      suffix++;
    }
    return id;
  }

  Channel _toChannel(M3uEntry entry, Set<String> existingIds) {
    final type = M3uService.detectSourceType(entry.url);
    final handle = M3uService.extractHandle(entry.url);
    final videoId = M3uService.extractVideoId(entry.url);
    return Channel(
      id: _autoId(entry.name, existingIds),
      name: entry.name,
      logoUrl: entry.logoUrl,
      streamUrl: type == 'hls' ? entry.url : null,
      youtubeHandle: handle,
      youtubeVideoId: type == 'youtube' ? videoId : null,
      category: _categoryFor(entry),
      sourceType: type,
    );
  }

  List<Channel> _selectedChannels() {
    final existingIds = widget.existingChannels.map((c) => c.id).toSet();
    return widget.entries
        .where((e) => _selected.contains(e.url))
        .map((e) => _toChannel(e, existingIds))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selected.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('M3U 가져오기 (${widget.entries.length}개 발견)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '선택 채널 추가',
            onPressed: selectedCount == 0
                ? null
                : () => Navigator.pop(context, _selectedChannels()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text('선택 $selectedCount개'),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _selected.clear();
                    _selected.addAll(widget.entries.map((e) => e.url));
                  }),
                  child: const Text('전체 선택'),
                ),
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('전체 해제'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.entries.length,
              itemBuilder: (context, index) {
                final entry = widget.entries[index];
                final hasGroup = entry.groupTitle.isNotEmpty;
                return CheckboxListTile(
                  dense: true,
                  value: _selected.contains(entry.url),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(entry.url);
                    } else {
                      _selected.remove(entry.url);
                    }
                  }),
                  title: Text(entry.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.url, style: const TextStyle(fontSize: 11)),
                      Row(
                        children: [
                          if (hasGroup) ...[
                            const Icon(Icons.folder, size: 14),
                            const SizedBox(width: 4),
                            Text(entry.groupTitle,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '→ ${_categoryFor(entry)}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.orange),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}