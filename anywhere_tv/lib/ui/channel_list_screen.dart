import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel.dart';
import '../repositories/channel_repository.dart';


class ChannelListScreen extends StatelessWidget {
  final ChannelRepository channelRepo;
  final String? currentChannelId;

  const ChannelListScreen({
    super.key,
    required this.channelRepo,
    this.currentChannelId,
  });

  static const _categoryOrder = ['지상파', '뉴스', '예능', '케이블', '음악', '교양', '드라마'];

  @override
  Widget build(BuildContext context) {
    final channels = channelRepo.channels;
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
      body: ListView(
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
                channel: channel,
                isCurrent: channel.id == currentChannelId,
                onTap: () => Navigator.of(context).pop({'channelId': channel.id}),
              ),
          ],
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
