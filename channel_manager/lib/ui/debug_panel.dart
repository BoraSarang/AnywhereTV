import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anywhere_shared/debug_logger.dart';

class DebugOverlay extends StatefulWidget {
  final Widget child;
  const DebugOverlay({super.key, required this.child});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  bool _isOpen = true;
  final GlobalKey<_DebugPanelWidgetState> _panelKey = GlobalKey();

  void toggle() => setState(() => _isOpen = !_isOpen);

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final key = event.logicalKey;

    if (meta && !shift && key == LogicalKeyboardKey.keyD) {
      toggle();
      return true;
    }
    if (!_isOpen) return false;
    if (meta && shift && key == LogicalKeyboardKey.keyC) {
      _panelKey.currentState?.copySelection();
      return true;
    }
    if (meta && shift && key == LogicalKeyboardKey.keyA) {
      _panelKey.currentState?.copyAll();
      return true;
    }
    if (meta && !shift && key == LogicalKeyboardKey.keyK) {
      _panelKey.currentState?.clear();
      return true;
    }
    if (meta && shift && key == LogicalKeyboardKey.keyS) {
      _panelKey.currentState?.toggleAutoScroll();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
    DebugLogger.instance.system('DebugPanel', 'Overlay init');
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          widget.child,
          if (!_isOpen)
            Positioned(
              bottom: 12, right: 12,
              child: GestureDetector(
                onTap: toggle,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xDE000000),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0x3DFFFFFF)),
                  ),
                  child: const Center(child: Text('🐛', style: TextStyle(fontSize: 22, decoration: TextDecoration.none))),
                ),
              ),
            ),
          if (_isOpen) Positioned(
            bottom: 60, left: 8, right: 8, height: 320,
            child: _DebugPanelWidget(key: _panelKey, onClose: toggle),
          ),
        ],
      ),
    );
  }
}

class _DebugPanelWidget extends StatefulWidget {
  final VoidCallback onClose;
  const _DebugPanelWidget({super.key, required this.onClose});

  @override
  State<_DebugPanelWidget> createState() => _DebugPanelWidgetState();
}

class _DebugPanelWidgetState extends State<_DebugPanelWidget> {
  final ScrollController _scrollController = ScrollController();
  final DebugLogger _logger = DebugLogger.instance;
  bool _autoScroll = true;
  bool _userScrolled = false;
  Timer? _resumeTimer;
  String _platformFilter = '';
  String _levelFilter = '';
  double _panelHeight = 320;
  final Set<int> _selection = {};
  int? _lastSelectedIndex;

  static const _levelFilters = ['', 'action', 'apiReq', 'apiRes', 'info', 'warn', 'error', 'system'];
  static const _levelFilterLabels = ['ALL', 'ACTION', 'API→', 'API←', 'INFO', 'WARN', 'ERROR', 'SYSTEM'];

  static const Color _cError = Color(0xFFFF6B6B);
  static const Color _cWarn = Color(0xFFFFD43B);
  static const Color _cApiReq = Color(0xFF74C0FC);
  static const Color _cApiRes = Color(0xFF8CE99A);
  static const Color _cSystem = Color(0xFFCC5DE8);
  static const Color _cAction = Color(0xFFFFFFFF);
  static const Color _cInfo = Color(0xFFAAAAAA);

  Color _textColor(LogLevel level) {
    switch (level) {
      case LogLevel.error: return _cError;
      case LogLevel.warn: return _cWarn;
      case LogLevel.apiReq: return _cApiReq;
      case LogLevel.apiRes: return _cApiRes;
      case LogLevel.system: return _cSystem;
      case LogLevel.action: return _cAction;
      case LogLevel.info: return _cInfo;
    }
  }

  List<LogEntry> get _filteredLogs {
    var list = _logger.logs;
    if (_platformFilter.isNotEmpty) {
      list = list.where((e) => e.platform == _platformFilter).toList();
    }
    if (_levelFilter.isNotEmpty) {
      list = list.where((e) => e.level.name == _levelFilter).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _logger.changeNotifier.addListener(_onLogChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _logger.changeNotifier.removeListener(_onLogChanged);
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogChanged() {
    if (!mounted) return;
    setState(() {});
    if (_autoScroll && !_logger.isAutoScrollPaused && !_userScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final atBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50;
    if (atBottom) {
      _userScrolled = false;
      _resumeTimer?.cancel();
    } else {
      _userScrolled = true;
      _logger.pauseAutoScroll();
      _resumeTimer?.cancel();
      _resumeTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _userScrolled = false;
          if (_autoScroll) _scrollToBottom();
          setState(() {});
        }
      });
    }
  }

  void _handleTap(int index, int logId) {
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isCmd = HardwareKeyboard.instance.isMetaPressed;
    _logger.pauseAutoScroll();

    setState(() {
      if (isCmd) {
        if (_selection.contains(logId)) {
          _selection.remove(logId);
        } else {
          _selection.add(logId);
        }
        _lastSelectedIndex = index;
      } else if (isShift && _lastSelectedIndex != null) {
        _selection.clear();
        final start = _lastSelectedIndex! < index ? _lastSelectedIndex! : index;
        final end = _lastSelectedIndex! < index ? index : _lastSelectedIndex!;
        final filtered = _filteredLogs;
        for (int i = start; i <= end && i < filtered.length; i++) {
          _selection.add(filtered[i].id);
        }
      } else {
        _selection.clear();
        _selection.add(logId);
        _lastSelectedIndex = index;
      }
    });
  }

  void copySelection() {
    final texts = _logger.logs
        .where((e) => _selection.contains(e.id))
        .map((e) => e.formatted)
        .join('\n');
    if (texts.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: texts));
    }
  }

  void copyAll() {
    Clipboard.setData(ClipboardData(text: _logger.formatForAgent(_filteredLogs)));
  }

  void toggleAutoScroll() {
    setState(() => _autoScroll = !_autoScroll);
  }

  void clear() {
    _logger.clear();
    setState(() {
      _selection.clear();
      _autoScroll = true;
      _userScrolled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        _panelHeight = (_panelHeight - d.delta.dy).clamp(150.0, 600.0);
        setState(() {});
        _logger.pauseAutoScroll();
      },
      child: Container(
        height: _panelHeight,
        decoration: const BoxDecoration(color: Color(0xE6000000)),
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text('no logs', style: TextStyle(fontSize: 14, color: Color(0x66FFFFFF), decoration: TextDecoration.none)))
                  : NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n is ScrollStartNotification || n is ScrollUpdateNotification) _onScroll();
                        return false;
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: logs.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        itemBuilder: (context, index) {
                          final e = logs[index];
                          final selected = _selection.contains(e.id);
                          return GestureDetector(
                            onTap: () => _handleTap(index, e.id),
                            child: Container(
                              color: selected ? const Color(0x4D0000FF) : Colors.transparent,
                              child: Text(
                                e.formatted,
                                style: TextStyle(
                                  fontFamily: 'Menlo',
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                  color: _textColor(e.level),
                                ),
                                softWrap: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          Text('🐛 Debug [${_logger.logs.length}]', style: const TextStyle(fontSize: 12, color: Color(0xCCFFFFFF), decoration: TextDecoration.none)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _autoScroll = !_autoScroll),
            child: Text(
              '📌 ${_autoScroll ? 'ON' : 'OFF'}',
              style: TextStyle(fontSize: 11, decoration: TextDecoration.none, color: _autoScroll ? const Color(0xCCFFFFFF) : const Color(0x66FFFFFF)),
            ),
          ),
          const Spacer(),
          if (_selection.isNotEmpty)
            _btn('copy sel(${_selection.length})', copySelection),
          if (_selection.isNotEmpty) const SizedBox(width: 4),
          _btn('copy all', copyAll),
          const SizedBox(width: 4),
          _btn('clear', clear),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 24, height: 24, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Color(0x1AFFFFFF), borderRadius: BorderRadius.all(Radius.circular(4))),
              child: const Text('X', style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF), decoration: TextDecoration.none)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _levelFilters.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  _filterChip(_levelFilter == _levelFilters[i], _levelFilterLabels[i], () {
                    setState(() => _levelFilter = _levelFilters[i]);
                  }),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(_platformFilter == '', 'ALL', () => setState(() => _platformFilter = '')),
                const SizedBox(width: 4),
                _filterChip(_platformFilter == 'macos', 'MACOS', () => setState(() => _platformFilter = 'macos')),
                const SizedBox(width: 4),
                _filterChip(_platformFilter == 'ios', 'IOS', () => setState(() => _platformFilter = 'ios')),
                const SizedBox(width: 4),
                _filterChip(_platformFilter == 'android', 'ANDROID', () => setState(() => _platformFilter = 'android')),
                const SizedBox(width: 4),
                _filterChip(_platformFilter == 'web', 'WEB', () => setState(() => _platformFilter = 'web')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(bool active, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0x26FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Menlo',
            decoration: TextDecoration.none,
            color: active ? const Color(0xFFFFFFFF) : const Color(0x66FFFFFF),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(color: Color(0x14FFFFFF), borderRadius: BorderRadius.all(Radius.circular(4))),
        child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xB3FFFFFF), decoration: TextDecoration.none)),
      ),
    );
  }
}
