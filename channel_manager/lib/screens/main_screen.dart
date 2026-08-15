import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/channel_store.dart';
import '../services/github_service.dart';
import '../services/health_service.dart';
import '../models/channel.dart';
import '../widgets/health_badge.dart';
import '../services/validation_service.dart';
import 'add_channel_screen.dart';
import 'edit_channel_screen.dart';
import 'category_manager_screen.dart';
import 'version_history_screen.dart';
import 'settings_screen.dart';
import 'test_play_screen.dart';
import 'health_report_screen.dart';
import 'm3u_import_screen.dart';
import 'ai_assistant_screen.dart';
import '../services/m3u_service.dart';

class UndoIntent extends Intent {}

class RedoIntent extends Intent {}

class MainScreen extends StatefulWidget {
  final ChannelStore store;
  final GitHubService github;
  final HealthService health;

  const MainScreen({
    super.key,
    required this.store,
    required this.github,
    required this.health,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedCategoryIndex = 0;
  List<String> _lastChannelIds = [];
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  Timer? _autoCheckTimer;

  ChannelStore get _store => widget.store;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _initAutoCheck();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  Future<void> _initAutoCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('auto_health_check') ?? false;
    if (!enabled || !mounted) return;
    _autoCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      widget.health.checkAll(_store.channels);
    });
  }

  void _onStoreChanged() {
    final ids = _store.channels.map((c) => c.id).toList();
    if (!listEquals(ids, _lastChannelIds)) {
      _lastChannelIds = ids;
      widget.health.invalidate(ids);
    }
  }

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
    return Shortcuts(
      shortcuts: {
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            UndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            RedoIntent(),
      },
      child: Actions(
        actions: {
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) {
              _store.undo();
              return null;
            },
          ),
          RedoIntent: CallbackAction<RedoIntent>(
            onInvoke: (_) {
              _store.redo();
              return null;
            },
          ),
        },
        child: ListenableBuilder(
      listenable: Listenable.merge([_store, widget.health]),
      builder: (context, _) {
        final channels = _selectedCategory != null
            ? _store.channelsInCategory(_selectedCategory!)
            : <Channel>[];
        return Scaffold(
          appBar: AppBar(
            title: Text('채널 관리자 v${_store.version}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.undo),
                tooltip: '실행 취소 (Cmd+Z)',
                onPressed: _store.canUndo ? _store.undo : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo),
                tooltip: '다시 실행 (Cmd+Shift+Z)',
                onPressed: _store.canRedo ? _store.redo : null,
              ),
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
                icon: const Icon(Icons.monitor_heart),
                tooltip: '전체 헬스체크',
                onPressed: widget.health.checking
                    ? null
                    : () => widget.health.checkAll(_store.channels),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.report),
                    if (widget.health.failedCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                              minWidth: 14, minHeight: 14),
                          child: Text(
                            '${widget.health.failedCount}',
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: '헬스체크 리포트',
                onPressed: () => _showHealthReport(),
              ),
              IconButton(
                icon: widget.health.checking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                tooltip: '채널 추가',
                onPressed: widget.health.checking ? null : _addChannel,
              ),
              IconButton(
                icon: const Icon(Icons.category),
                tooltip: '카테고리 관리',
                onPressed: _manageCategories,
              ),
              IconButton(
                icon: Icon(
                  _selectionMode ? Icons.checklist_rtl : Icons.checklist,
                ),
                tooltip: _selectionMode ? '선택 모드 종료' : '일괄 편집',
                onPressed: () => setState(() {
                  _selectionMode = !_selectionMode;
                  _selectedIds.clear();
                }),
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: '버전 기록',
                onPressed: _showHistory,
              ),
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                tooltip: 'AI 어시스턴트',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AiAssistantScreen(store: _store),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.file_open),
                tooltip: 'M3U 가져오기/내보내기',
                onSelected: (value) {
                  if (value == 'export') _exportM3u();
                  if (value == 'import') _importM3u();
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 'export', child: Text('M3U 내보내기')),
                  PopupMenuItem(value: 'import', child: Text('M3U 가져오기')),
                ],
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
          bottomNavigationBar:
              _selectionMode ? _buildSelectionBar(channels) : null,
        );
      },
        ),
      ),
    );
  }

  Widget _buildSelectionBar(List<Channel> channels) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('선택 ${_selectedIds.length}개'),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('실패 채널 선택'),
                onPressed: () {
                  final failedIds = widget.health
                      .failedFor(channels)
                      .map((e) => e.key.id)
                      .toSet();
                  setState(() {
                    _selectedIds
                      ..clear()
                      ..addAll(failedIds);
                  });
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.drive_file_move),
                tooltip: '카테고리 이동',
                onPressed: _selectedIds.isEmpty ? null : _moveSelected,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: '선택 삭제',
                onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: '선택 모드 종료',
                onPressed: () => setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _moveSelected() async {
    final category = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('이동할 카테고리 선택'),
        children: _store.categories
            .map((c) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, c),
                  child: Text(c),
                ))
            .toList(),
      ),
    );
    if (category == null || !mounted) return;
    final all = _store.channels;
    for (final ch in all) {
      if (_selectedIds.contains(ch.id) && ch.category != category) {
        _store.updateChannel(
          all.indexOf(ch),
          ch.copyWith(category: category),
        );
      }
    }
    setState(_selectedIds.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('선택 채널을 "$category"(으)로 이동했습니다')),
    );
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('선택 채널 삭제'),
        content: Text('선택한 ${_selectedIds.length}개 채널을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              final all = _store.channels;
              for (final ch in all.toList().reversed) {
                if (_selectedIds.contains(ch.id)) {
                  _store.removeChannel(all.indexOf(ch));
                }
              }
              setState(_selectedIds.clear);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
        final catChannels = _store.channelsInCategory(cats[index]);
        final count = catChannels.length;
        final liveCount =
            catChannels.where((c) => widget.health.statusFor(c.id) == HealthStatus.ok).length;
        return ListTile(
          selected: isSelected,
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          title: Text(cats[index]),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (liveCount > 0) ...[
                const Icon(Icons.circle, size: 10, color: Colors.green),
                const SizedBox(width: 4),
                Text('$liveCount', style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
              ],
              Text('$count', style: const TextStyle(fontSize: 12)),
            ],
          ),
          onTap: () => setState(() => _selectedCategoryIndex = index),
        );
      },
    );
  }

  Widget _buildChannelList(List<Channel> channels) {
    if (channels.isEmpty) {
      return const Center(child: Text('이 카테고리에 채널이 없습니다'));
    }
    final okCount = widget.health.okCount;
    final failedCount = widget.health.failedCount;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Row(
            children: [
              const Icon(Icons.circle, size: 12, color: Colors.green),
              const SizedBox(width: 4),
              Text('온라인 $okCount'),
              const SizedBox(width: 12),
              const Icon(Icons.circle, size: 12, color: Colors.red),
              const SizedBox(width: 4),
              Text('오프라인 $failedCount'),
              const SizedBox(width: 12),
              const Icon(Icons.circle, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text('미확인 ${widget.health.unknownCount}'),
              const Spacer(),
              if (widget.health.checking)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildReorderableList(channels),
        ),
      ],
    );
  }

  Widget _buildReorderableList(List<Channel> channels) {
    final issuesByChannel = <String, List<ValidationIssue>>{};
    for (final issue in ValidationService.validate(
      channels: channels,
      categories: _store.categories,
    )) {
      issuesByChannel.putIfAbsent(issue.channelId, () => []).add(issue);
    }
    return ReorderableListView.builder(
      itemCount: channels.length,
      onReorder: (oldIndex, newIndex) {
        _store.reorderChannels(_selectedCategory!, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final ch = channels[index];
        final health = widget.health.results[ch.id];
        return _ChannelRow(
          key: ValueKey(ch.id),
          channel: ch,
          health: health,
          issues: issuesByChannel[ch.id],
          selectionMode: _selectionMode,
          selected: _selectedIds.contains(ch.id),
          onToggleSelect: () => setState(() {
            if (!_selectedIds.add(ch.id)) _selectedIds.remove(ch.id);
          }),
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

  void _showHealthReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthReportScreen(
          health: widget.health,
          channels: _store.channels,
        ),
      ),
    );
  }

  Future<void> _exportM3u() async {
    final content = M3uService.export(_store.channels);
    const typeGroup = XTypeGroup(label: 'M3U', extensions: ['m3u']);
    final location = await getSaveLocation(
      suggestedName: 'channels_export.m3u',
      acceptedTypeGroups: const [typeGroup],
    );
    if (location == null || !mounted) return;
    final path = location.path;
    try {
      await File(path).writeAsString(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('M3U 내보내기 완료: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('내보내기 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importM3u() async {
    const typeGroup = XTypeGroup(label: 'M3U', extensions: ['m3u']);
    final file = await openFile(acceptedTypeGroups: const [typeGroup]);
    if (file == null) return;
    final content = await file.readAsString();
    final entries = M3uService.parse(content);
    if (!mounted) return;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('M3U 파일에서 채널을 찾지 못했습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final channels = await Navigator.push<List<Channel>>(
      context,
      MaterialPageRoute(
        builder: (_) => M3uImportScreen(
          entries: entries,
          categories: _store.categories,
        ),
      ),
    );
    if (channels == null || !mounted) return;
    for (final ch in channels) {
      if (!_store.categories.contains(ch.category)) {
        _store.addCategory(ch.category);
      }
      _store.addChannel(ch);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('채널 ${channels.length}개 추가 완료')),
    );
  }

  Future<void> _saveToGist() async {
    final issues = ValidationService.validate(
      channels: _store.channels,
      categories: _store.categories,
    );
    if (issues.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('저장 전 검증 (문제 ${issues.length}건)'),
          content: SizedBox(
            width: 400,
            child: ListView(
              shrinkWrap: true,
              children: issues
                  .map((issue) => ListTile(
                        dense: true,
                        leading: Icon(
                          issue.severity == ValidationSeverity.error
                              ? Icons.error
                              : Icons.warning,
                          color: issue.severity == ValidationSeverity.error
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(issue.channelName),
                        subtitle: Text(issue.message),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('그래도 저장'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
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
  final ChannelHealth? health;
  final List<ValidationIssue>? issues;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onPlay;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChannelRow({
    super.key,
    required this.channel,
    this.health,
    this.issues,
    this.selectionMode = false,
    this.selected = false,
    required this.onToggleSelect,
    required this.onPlay,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: selectionMode
            ? Checkbox(
                value: selected,
                onChanged: (_) => onToggleSelect(),
              )
            : channel.logoUrl.isNotEmpty
                ? Image.network(channel.logoUrl, width: 40, height: 40,
                    errorBuilder: (_, _, _) => const Icon(Icons.tv))
                : const Icon(Icons.tv),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (health != null) ...[
              HealthBadge(
                status: health!.status,
                message: health!.message,
                latencyMs: health!.latencyMs,
              ),
              const SizedBox(width: 6),
            ],
            if (issues != null && issues!.isNotEmpty) ...[
              Tooltip(
                message: issues!.map((i) => i.message).join('\n'),
                child: Icon(
                  issues!.any((i) => i.severity == ValidationSeverity.error)
                      ? Icons.error
                      : Icons.warning_amber,
                  size: 18,
                  color: issues!.any((i) => i.severity == ValidationSeverity.error)
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Flexible(child: Text(channel.name)),
          ],
        ),
        onTap: selectionMode ? onToggleSelect : null,
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
