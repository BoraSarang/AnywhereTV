import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../repositories/channel_repository.dart';

class ChannelListScreen extends StatefulWidget {
  final ChannelRepository channelRepo;
  final String? currentChannelId;

  const ChannelListScreen({
    super.key,
    required this.channelRepo,
    this.currentChannelId,
  });

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _tileKeys = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

    final grouped = <String, List<Channel>>{};
    for (final c in filtered) {
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
                      for (final entry in sortedCategories) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            entry.key,
                            style: const TextStyle(color: Color(0xFF533483), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        for (final channel in entry.value)
                          _ChannelTile(
                            key: _tileKeys.putIfAbsent(channel.id, () => GlobalKey()),
                            channel: channel,
                            isCurrent: channel.id == widget.currentChannelId,
                            onTap: () => Navigator.of(context).pop({'channelId': channel.id}),
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

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ChannelTile({
    super.key,
    required this.channel,
    required this.isCurrent,
    required this.onTap,
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
        subtitle: Text(channel.sourceType == 'youtube_live' ? 'YouTube' : 'HLS',
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF533483),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('재생중', style: TextStyle(color: Colors.white, fontSize: 11)),
              )
            : const Icon(Icons.play_arrow, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}
