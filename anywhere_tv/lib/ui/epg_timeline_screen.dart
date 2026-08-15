import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../services/epg_service.dart';
import '../services/error_messages.dart';
import 'package:anywhere_shared/debug_logger.dart';

class EpgTimelineScreen extends StatefulWidget {
  final Channel channel;
  final String? epgServerUrl;

  const EpgTimelineScreen({
    super.key,
    required this.channel,
    this.epgServerUrl,
  });

  @override
  State<EpgTimelineScreen> createState() => _EpgTimelineScreenState();
}

class _EpgTimelineScreenState extends State<EpgTimelineScreen> {
  List<EpgProgram> _programs = [];
  bool _loading = true;
  String? _error;
  final DebugLogger _log = DebugLogger.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final epgUrl = widget.channel.epgUrl ?? widget.epgServerUrl;
    if (epgUrl == null || epgUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = ErrorMessages.get('E-COM-EPG-1002', fallback: 'EPG 서버 URL이 설정되지 않았습니다.\n설정에서 XMLTV 주소를 입력해 주세요.');
      });
      _log.system('EPG', 'Timeline: no EPG URL for ${widget.channel.id}');
      return;
    }
    try {
      final programs = await EpgService.fetchFromUrl(epgUrl, widget.channel.id);
      if (!mounted) return;
      setState(() {
        _programs = programs;
        _loading = false;
      });
      _log.system('EPG', 'Timeline loaded: ${programs.length} programs for ${widget.channel.id}');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '${ErrorMessages.get('E-COM-EPG-1001')}\n$e';
      });
      _log.warn('EPG', 'Timeline load failed: $e');
    }
  }

  DateTime get _today => DateTime.now();

  List<EpgProgram> _filterToday() {
    final start = DateTime(_today.year, _today.month, _today.day);
    final end = start.add(const Duration(days: 1));
    final list = _programs
        .where((p) => p.endTime.isAfter(start) && p.startTime.isBefore(end))
        .toList();
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.channel.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
            const Text('오늘 편성표', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text('다시 시도', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      );
    }
    final today = _filterToday();
    if (today.isEmpty) {
      return const Center(
        child: Text('오늘 편성표가 없습니다.', style: TextStyle(color: Colors.white54, fontSize: 14)),
      );
    }
    return _TimelineView(
      programs: today,
      now: DateTime.now(),
      onRefresh: _load,
    );
  }
}

class _TimelineView extends StatelessWidget {
  final List<EpgProgram> programs;
  final DateTime now;
  final VoidCallback onRefresh;

  const _TimelineView({
    required this.programs,
    required this.now,
    required this.onRefresh,
  });

  static const _hourHeight = 64.0;
  static const _hourLabelWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final totalHeight = 24 * _hourHeight;

    final nowPos = now.difference(dayStart).inMinutes / 60.0 * _hourHeight;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: totalHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hourLabels(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        _hourGridLines(width: constraints.maxWidth),
                        ...programs.map((p) {
                          final start = p.startTime.isBefore(dayStart) ? dayStart : p.startTime;
                          final end = p.endTime.isAfter(dayEnd) ? dayEnd : p.endTime;
                          final top = start.difference(dayStart).inMinutes / 60.0 * _hourHeight;
                          final height = end.difference(start).inMinutes / 60.0 * _hourHeight;
                          return _ProgramBar(
                            program: p,
                            top: top,
                            height: height,
                            width: constraints.maxWidth,
                            now: now,
                          );
                        }),
                        if (nowPos >= 0 && nowPos <= totalHeight)
                          Positioned(
                            top: nowPos,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              color: const Color(0xFFE03131),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hourLabels() {
    return SizedBox(
      width: _hourLabelWidth,
      height: 24 * _hourHeight,
      child: Column(
        children: [
          for (var h = 0; h < 24; h++)
            SizedBox(
              height: _hourHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: 8),
                  child: Text(
                    '$h시',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _hourGridLines({required double width}) {
    return Column(
      children: [
        for (var h = 1; h < 24; h++)
          SizedBox(
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(height: 1, color: Colors.white12),
            ),
          ),
      ],
    );
  }
}

class _ProgramBar extends StatelessWidget {
  final EpgProgram program;
  final double top;
  final double height;
  final double width;
  final DateTime now;

  const _ProgramBar({
    required this.program,
    required this.top,
    required this.height,
    required this.width,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    final isNow = program.isCurrentlyAiring;
    final isUpcoming = program.startTime.isAfter(now);
    final color = isNow
        ? const Color(0xFF533483)
        : isUpcoming
            ? const Color(0xFF2B2B44)
            : const Color(0xFF1F1F38);
    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height < 18 ? 18 : height,
      child: GestureDetector(
        onTap: () => _showDetail(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: isNow ? Border.all(color: const Color(0xFFE03131), width: 1.5) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_fmt(program.startTime)} - ${_fmt(program.endTime)}',
                style: TextStyle(
                  color: isNow ? Colors.white : Colors.white54,
                  fontSize: 10,
                ),
              ),
              Expanded(
                child: Text(
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isNow ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isNow ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showDetail(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: Text(program.title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_fmt(program.startTime)} ~ ${_fmt(program.endTime)}'
              '${program.category != null && program.category!.isNotEmpty ? ' · ${program.category}' : ''}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (program.description != null && program.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(program.description!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('닫기', style: TextStyle(color: Color(0xFF74C0FC))),
          ),
        ],
      ),
    );
  }
}