import 'package:flutter/material.dart';
import '../services/channel_store.dart';
import '../services/github_service.dart';
import '../models/channel.dart';
import 'add_channel_screen.dart';
import 'edit_channel_screen.dart';
import 'category_manager_screen.dart';
import 'version_history_screen.dart';
import 'settings_screen.dart';
import 'test_play_screen.dart';

class MainScreen extends StatefulWidget {
  final ChannelStore store;
  final GitHubService github;

  const MainScreen({super.key, required this.store, required this.github});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedCategoryIndex = 0;

  ChannelStore get _store => widget.store;

  String? get _selectedCategory {
    final cats = _store.categories;
    if (cats.isEmpty) return null;
    if (_selectedCategoryIndex >= cats.length) {
      _selectedCategoryIndex = 0;
    }
    return cats.isEmpty ? null : cats[_selectedCategoryIndex];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final channels = _selectedCategory != null
            ? _store.channelsInCategory(_selectedCategory!)
            : <Channel>[];
        return Scaffold(
          appBar: AppBar(
            title: Text('채널 관리자 v${_store.version}'),
            actions: [
              if (_store.dirty)
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'Gist에 저장',
                  onPressed: _saveToGist,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(Colors.orange),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '채널 추가',
                onPressed: _addChannel,
              ),
              IconButton(
                icon: const Icon(Icons.category),
                tooltip: '카테고리 관리',
                onPressed: _manageCategories,
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: '버전 기록',
                onPressed: _showHistory,
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: '설정',
                onPressed: _showSettings,
              ),
            ],
          ),
          body: _store.loading
              ? const Center(child: CircularProgressIndicator())
              : _store.error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('오류: ${_store.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _store.loadFromRemote(),
                            child: const Text('재시도'),
                          ),
                          ElevatedButton(
                            onPressed: _showSettings,
                            child: const Text('설정'),
                          ),
                        ],
                      ),
                    )
                  : _store.categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tv, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('불러온 채널이 없습니다'),
                              const SizedBox(height: 8),
                              const Text('설정에서 Gist 주소를 확인하거나 새로 시작하세요.'),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.settings),
                                label: const Text('설정'),
                                onPressed: _showSettings,
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: 200,
                              child: _buildCategoryList(),
                            ),
                            const VerticalDivider(width: 1),
                            Expanded(child: _buildChannelList(channels)),
                          ],
                        ),
        );
      },
    );
  }

  Widget _buildCategoryList() {
    final cats = _store.categories;
    if (cats.isEmpty) {
      return const Center(child: Text('카테고리 없음'));
    }
    return ListView.builder(
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final isSelected = index == _selectedCategoryIndex;
        final count = _store.channelsInCategory(cats[index]).length;
        return ListTile(
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(cats[index]),
          trailing: Text('$count', style: const TextStyle(fontSize: 12)),
          onTap: () => setState(() => _selectedCategoryIndex = index),
        );
      },
    );
  }

  Widget _buildChannelList(List<Channel> channels) {
    if (channels.isEmpty) {
      return const Center(child: Text('이 카테고리에 채널이 없습니다'));
    }
    return ReorderableListView.builder(
      itemCount: channels.length,
      onReorder: (oldIndex, newIndex) {
        _store.reorderChannels(_selectedCategory!, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final ch = channels[index];
        return _ChannelRow(
          key: ValueKey(ch.id),
          channel: ch,
          onPlay: () => _testPlay(ch),
          onEdit: () => _editChannel(ch),
          onDelete: () => _deleteChannel(ch),
        );
      },
    );
  }

  Future<void> _addChannel() async {
    final result = await Navigator.push<Channel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddChannelScreen(categories: _store.categories),
      ),
    );
    if (result != null && mounted) {
      _store.addChannel(result);
    }
  }

  Future<void> _editChannel(Channel ch) async {
    final globalIndex = _store.channels.indexOf(ch);
    final result = await Navigator.push<Channel>(
      context,
      MaterialPageRoute(
        builder: (_) => EditChannelScreen(
          channel: ch,
          categories: _store.categories,
        ),
      ),
    );
    if (result != null && mounted) {
      _store.updateChannel(globalIndex, result);
    }
  }

  void _deleteChannel(Channel ch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('채널 삭제'),
        content: Text('"${ch.name}"을(를) 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final globalIndex = _store.channels.indexOf(ch);
              _store.removeChannel(globalIndex);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _testPlay(Channel ch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestPlayScreen(channel: ch),
      ),
    );
  }

  void _manageCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryManagerScreen(store: _store),
      ),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VersionHistoryScreen(store: _store),
      ),
    );
  }

  void _showSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(github: widget.github, store: _store),
      ),
    );
  }

  Future<void> _saveToGist() async {
    final ok = await _store.saveToRemote();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Gist에 저장 완료' : '저장 실패 (토큰이 필요합니다)'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final Channel channel;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChannelRow({
    super.key,
    required this.channel,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: channel.logoUrl.isNotEmpty
            ? Image.network(channel.logoUrl, width: 40, height: 40,
                errorBuilder: (_, __, ___) => const Icon(Icons.tv))
            : const Icon(Icons.tv),
        title: Text(channel.name),
        subtitle: Text(channel.category, style: const TextStyle(fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.play_arrow), tooltip: '테스트 재생', onPressed: onPlay),
            IconButton(icon: const Icon(Icons.edit), tooltip: '편집', onPressed: onEdit),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: '삭제',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
