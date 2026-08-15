import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:anywhere_shared/debug_logger.dart';
import '../models/channel.dart';
import 'github_service.dart';
import 'backup_service.dart';

class HistoryEntry {
  final int version;
  final String date;
  final List<String> changes;

  HistoryEntry({required this.version, required this.date, required this.changes});

  Map<String, dynamic> toJson() => {'version': version, 'date': date, 'changes': changes};

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    version: json['version'] as int,
    date: json['date'] as String,
    changes: (json['changes'] as List<dynamic>).map((c) => c as String).toList(),
  );
}

class _StoreSnapshot {
  final List<Channel> channels;
  final List<String> categories;
  final int version;
  final String updatedAt;
  final List<HistoryEntry> history;
  final List<String> pendingChanges;

  _StoreSnapshot({
    required this.channels,
    required this.categories,
    required this.version,
    required this.updatedAt,
    required this.history,
    required this.pendingChanges,
  });
}

class ChannelStore extends ChangeNotifier {
  static const int _maxUndo = 50;
  static final DebugLogger _log = DebugLogger.instance;

  final GitHubService _github;

  ChannelStore(this._github);

  List<Channel> _channels = [];
  List<String> _categories = [];
  List<HistoryEntry> _history = [];
  int _version = 1;
  String _remoteUrl = '';
  String _updatedAt = '';
  bool _loading = false;
  String? _error;
  bool _dirty = false;
  List<String> _pendingChanges = [];
  bool _hasConfig = false;
  final List<_StoreSnapshot> _undoStack = [];
  final List<_StoreSnapshot> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  List<Channel> get channels => List.unmodifiable(_channels);
  List<String> get categories => List.unmodifiable(_categories);
  List<HistoryEntry> get history => List.unmodifiable(_history);
  int get version => _version;
  String get remoteUrl => _remoteUrl;
  String get updatedAt => _updatedAt;
  bool get loading => _loading;
  String? get error => _error;
  bool get dirty => _dirty;
  bool get hasConfig => _hasConfig;

  List<Channel> channelsInCategory(String category) =>
    _channels.where((c) => c.category == category).toList();

  Future<bool> loadFromRemote() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final raw = await _github.fetchFromRawUrl();
      if (raw == null) {
        _error = '원격 URL에서 데이터를 가져올 수 없습니다';
        _loading = false;
        notifyListeners();
        return false;
      }
      _parseJson(raw);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void _parseJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _version = json['version'] as int? ?? 1;
    _updatedAt = json['updatedAt'] as String? ?? '';
    _remoteUrl = json['remoteUrl'] as String? ?? '';
    _channels = (json['channels'] as List<dynamic>?)
        ?.map((e) => Channel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    _categories = (json['categories'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];
    if (_categories.isEmpty) {
      final cats = _channels.map((c) => c.category).toSet().toList()..sort();
      _categories.addAll(cats);
    }
    final historyRaw = json['history'] as List<dynamic>?;
    _history = historyRaw
        ?.map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];
    _dirty = false;
    _pendingChanges = [];
    _undoStack.clear();
    _redoStack.clear();
  }

  _StoreSnapshot _snapshot() => _StoreSnapshot(
        channels: List.of(_channels),
        categories: List.of(_categories),
        version: _version,
        updatedAt: _updatedAt,
        history: List.of(_history),
        pendingChanges: List.of(_pendingChanges),
      );

  void _restore(_StoreSnapshot snap) {
    _channels = List.of(snap.channels);
    _categories = List.of(snap.categories);
    _version = snap.version;
    _updatedAt = snap.updatedAt;
    _history = List.of(snap.history);
    _pendingChanges = List.of(snap.pendingChanges);
    _dirty = true;
  }

  void _recordUndo() {
    _undoStack.add(_snapshot());
    if (_undoStack.length > _maxUndo) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_snapshot());
    _restore(_undoStack.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_snapshot());
    _restore(_redoStack.removeLast());
    notifyListeners();
  }

  String _toJson() {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return const JsonEncoder.withIndent('  ').convert({
      'version': _version,
      'updatedAt': dateStr,
      'remoteUrl': _remoteUrl,
      'categories': _categories,
      'history': _history.map((h) => h.toJson()).toList(),
      'channels': _channels.map((c) => c.toJson()).toList(),
    });
  }

  String generateJson() => _toJson();

  Future<bool> saveToRemote({String? message}) async {
    final changes = _pendingChanges.isEmpty ? ['채널 업데이트'] : _pendingChanges;
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _version++;
    _history.insert(0, HistoryEntry(version: _version, date: dateStr, changes: changes));
    _pendingChanges = [];
    _dirty = false;
    final json = _toJson();
    final msg = message ?? 'v$_version: ${changes.join(', ')}';
    final ok = await _github.uploadToGist(json, message: msg);
    if (ok) {
      await BackupService.saveBackup(content: json, version: _version);
    } else {
      _dirty = true;
    }
    notifyListeners();
    return ok;
  }

  void applyAiResult({
    required List<Channel> channels,
    required List<String> categories,
  }) {
    _recordUndo();
    _channels = List.of(channels);
    _categories = List.of(categories);
    _dirty = true;
    _pendingChanges.add('AI 변경 적용');
    notifyListeners();
  }

  void addChannel(Channel channel) {
    _recordUndo();
    final sameCatIdx = _channels.indexWhere((c) => c.category == channel.category);
    final insertIdx = sameCatIdx == -1 ? _channels.length : sameCatIdx;
    _channels.insert(insertIdx, channel);
    _dirty = true;
    _pendingChanges.add('추가: ${channel.name}');
    _log.info('Store',
        '채널 추가: ${channel.id} (${channel.category}) — 총 ${_channels.length}개');
    notifyListeners();
  }

  void updateChannel(int index, Channel channel) {
    _recordUndo();
    _channels[index] = channel;
    _dirty = true;
    _pendingChanges.add('수정: ${channel.name}');
    _log.info('Store', '채널 수정: ${channel.id} (${channel.category})');
    notifyListeners();
  }

  void removeChannel(int index) {
    _recordUndo();
    final name = _channels[index].name;
    _channels.removeAt(index);
    _dirty = true;
    _pendingChanges.add('삭제: $name');
    notifyListeners();
  }

  void addCategory(String name) {
    if (!_categories.contains(name)) {
      _recordUndo();
      _categories.add(name);
      _dirty = true;
      _pendingChanges.add('카테고리 추가: $name');
      notifyListeners();
    }
  }

  void renameCategory(String oldName, String newName) {
    final idx = _categories.indexOf(oldName);
    if (idx < 0) return;
    _recordUndo();
    _categories[idx] = newName;
    for (int i = 0; i < _channels.length; i++) {
      if (_channels[i].category == oldName) {
        _channels[i] = _channels[i].copyWith(category: newName);
      }
    }
    _dirty = true;
      _pendingChanges.add('카테고리 이름 변경: $oldName → $newName');
    notifyListeners();
  }

  void deleteCategory(String name) {
    _recordUndo();
    _categories.remove(name);
    _dirty = true;
    _pendingChanges.add('카테고리 삭제: $name');
    notifyListeners();
  }

  void reorderCategories(int oldIndex, int newIndex) {
    _recordUndo();
    if (oldIndex < newIndex) newIndex--;
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    _dirty = true;
    notifyListeners();
  }

  void reorderChannels(String category, int oldIndex, int newIndex) {
    _recordUndo();
    final catChannels = channelsInCategory(category);
    if (oldIndex >= catChannels.length || newIndex > catChannels.length) return;
    final globalOld = _channels.indexOf(catChannels[oldIndex]);
    if (oldIndex < newIndex) {
      final globalNew = _channels.indexOf(catChannels[newIndex - 1]);
      if (globalNew < 0) return;
      final item = _channels.removeAt(globalOld);
      _channels.insert(globalNew, item);
    } else {
      final globalNew = _channels.indexOf(catChannels[newIndex]);
      if (globalNew < 0) return;
      final item = _channels.removeAt(globalOld);
      _channels.insert(globalNew, item);
    }
    _dirty = true;
    notifyListeners();
  }
}
