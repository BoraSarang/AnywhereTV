import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import '../models/channel.dart';
import '../models/epg_program.dart';
import '../repositories/channel_repository.dart';
import '../services/epg_service.dart';
import 'package:anywhere_shared/debug_logger.dart';

class ChannelListScreen extends StatefulWidget {
  final ChannelRepository channelRepo;
  final String? currentChannelId;
  final List<String> favoriteChannelIds;
  final ValueChanged<List<String>> onFavoritesChanged;
  final List<String> watchHistory;
  final String? epgServerUrl;

  const ChannelListScreen({
    super.key,
    required this.channelRepo,
    required this.favoriteChannelIds,
    required this.onFavoritesChanged,
    required this.watchHistory,
    this.currentChannelId,
    this.epgServerUrl,
  });

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _tileKeys = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Map<String, EpgProgram> _currentPrograms = {};
  final DebugLogger _log = DebugLogger.instance;

  List<String> get _categoryOrder {
    final order = <String>[];
    for (final ch in widget.channelRepo.channels) {
      if (!order.contains(ch.category)) order.add(ch.category);
    }
    return order;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
    _fetchCurrentPrograms();
  }

  Future<void> _fetchCurrentPrograms() async {
    for (final channel in widget.channelRepo.channels) {
      final epgUrl = channel.epgUrl ?? widget.epgServerUrl;
      if (epgUrl == null || epgUrl.isEmpty || _currentPrograms.containsKey(channel.id)) {
        continue;
      }
      try {
        final programs = await EpgService.fetchFromUrl(epgUrl, channel.id);
        final current = EpgService.currentProgram(programs);
        if (current != null && mounted) {
          setState(() => _currentPrograms[channel.id] = current);
        }
      } catch (e) {
        _log.warn('EPG', 'Current program fetch failed for ${channel.id}: $e');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (widget.currentChannelId == null) return;
    final id = widget.currentChannelId!;
    final channels = widget.channelRepo.channels;
    final grouped = <String, List<Channel>>{};
    for (final c in channels) {
      grouped.putIfAbsent(c.category, () => []).add(c);
    }
    final sortedCategories = grouped.entries.toList()
      ..sort((a, b) {
        final ai = _categoryOrder.indexOf(a.key);
        final bi = _categoryOrder.indexOf(b.key);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });

    double offset = 0;
    const double headerHeight = 50;
    const double tileHeight = 76;

    outer:
    for (final entry in sortedCategories) {
      offset += headerHeight;
      for (final ch in entry.value) {
        if (ch.id == id) break outer;
        offset += tileHeight;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!_scrollController.hasClients) return;
        final target = (offset - 100).clamp(0.0, _scrollController.position.maxScrollExtent);
        if (target > 0) {
          _scrollController.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final allChannels = widget.channelRepo.channels;
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? allChannels
        : allChannels.where((c) => c.name.toLowerCase().contains(query)).toList();

    final favorites = query.isEmpty
        ? widget.favoriteChannelIds
            .map((id) => allChannels.where((c) => c.id == id).toList())
            .where((l) => l.isNotEmpty)
            .map((l) => l.first)
            .toList()
        : <Channel>[];

    final recent = query.isEmpty
        ? widget.watchHistory
            .map((id) => allChannels.where((c) => c.id == id).toList())
            .where((l) => l.isNotEmpty)
            .map((l) => l.first)
            .where((c) => !favorites.any((f) => f.id == c.id))
            .take(5)
            .toList()
        : <Channel>[];

    final grouped = <String, List<Channel>>{};
    for (final c in filtered) {
      if (query.isEmpty && favorites.any((f) => f.id == c.id)) continue;
      grouped.putIfAbsent(c.category, () => []).add(c);
    }
    final sortedCategories = grouped.entries.toList()
      ..sort((a, b) {
        final ai = _categoryOrder.indexOf(a.key);
        final bi = _categoryOrder.indexOf(b.key);
        return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
      });

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('채널 목록', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() { _searchQuery = v; }),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '채널 검색...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white38),
                        onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; }); },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  )
                : ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (query.isEmpty && recent.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '최근 시청',
                            style: TextStyle(color: Color(0xFF533483), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (final channel in recent)
                          DpadFocusable(
                            key: ValueKey('recent-${channel.id}'),
                            onSelect: () =>
                                Navigator.of(context).pop({'channelId': channel.id}),
                            child: _ChannelTile(
                              channel: channel,
                              isCurrent: channel.id == widget.currentChannelId,
                              currentProgramTitle: _currentPrograms[channel.id]?.title,
                              onTap: () =>
                                  Navigator.of(context).pop({'channelId': channel.id}),
                            ),
                          ),
                      ],
                      if (query.isEmpty && favorites.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            '즐겨찾기 (길게 눌러 순서 변경)',
                            style: TextStyle(color: Color(0xFF533483), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        _FavoriteReorderList(
                          channels: favorites,
                          currentPrograms: _currentPrograms,
                          currentChannelId: widget.currentChannelId,
                          onTap: (channel) =>
                              Navigator.of(context).pop({'channelId': channel.id}),
                          onReorder: (from, to) {
                            final updated = List<String>.from(widget.favoriteChannelIds);
                            final moved = updated.removeAt(from);
                            updated.insert(to, moved);
                            widget.onFavoritesChanged(updated);
                          },
                        ),
                      ],
                      for (final entry in sortedCategories) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: Color(0xFF533483), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (final channel in entry.value)
                          DpadFocusable(
                            key: ValueKey('channel-${channel.id}'),
                            onSelect: () =>
                                Navigator.of(context).pop({'channelId': channel.id}),
                            child: _ChannelTile(
                              key: _tileKeys.putIfAbsent(channel.id, () => GlobalKey()),
                              channel: channel,
                              isCurrent: channel.id == widget.currentChannelId,
                              currentProgramTitle: _currentPrograms[channel.id]?.title,
                              onTap: () => Navigator.of(context).pop({'channelId': channel.id}),
                            ),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteReorderList extends StatelessWidget {
  final List<Channel> channels;
  final String? currentChannelId;
  final ValueChanged<Channel> onTap;
  final ReorderCallback onReorder;
  final Map<String, EpgProgram> currentPrograms;

  const _FavoriteReorderList({
    required this.channels,
    required this.currentChannelId,
    required this.onTap,
    required this.onReorder,
    required this.currentPrograms,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: channels.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final channel = channels[index];
        return ReorderableDelayedDragStartListener(
          key: ValueKey(channel.id),
          index: index,
          child: _ChannelTile(
            channel: channel,
            isCurrent: channel.id == currentChannelId,
            currentProgramTitle: currentPrograms[channel.id]?.title,
            onTap: () => onTap(channel),
            dragHandle: true,
          ),
        );
      },
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isCurrent;
  final VoidCallback onTap;
  final bool dragHandle;
  final String? currentProgramTitle;

  const _ChannelTile({
    super.key,
    required this.channel,
    required this.isCurrent,
    required this.onTap,
    this.dragHandle = false,
    this.currentProgramTitle,
  });

  Widget _buildLogo() {
    if (channel.logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: channel.logoUrl,
          width: 40, height: 40,
          fit: BoxFit.contain,
          placeholder: (_, __) => Container(
            width: 40, height: 40,
            color: const Color(0xFF0F3460),
          ),
          errorWidget: (_, __, ___) => _initialLetter(),
        ),
      );
    }
    return _initialLetter();
  }

  Widget _initialLetter() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          channel.name.substring(0, 1),
          style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0x33533483) : const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(10),
        border: isCurrent ? Border.all(color: const Color(0xFF533483), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: _buildLogo(),
        title: Text(channel.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(channel.sourceType == 'youtube_live' ? 'YouTube' : 'HLS',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            if (currentProgramTitle != null && currentProgramTitle!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  currentProgramTitle!,
                  style: const TextStyle(color: Color(0xFF8CE99A), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF533483),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('재생중', style: TextStyle(color: Colors.white, fontSize: 11)),
              )
            : Icon(dragHandle ? Icons.drag_indicator : Icons.play_arrow, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
