import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/health_service.dart';
import 'test_play_screen.dart';

class HealthReportScreen extends StatefulWidget {
  final HealthService health;
  final List<Channel> channels;

  const HealthReportScreen({
    super.key,
    required this.health,
    required this.channels,
  });

  @override
  State<HealthReportScreen> createState() => _HealthReportScreenState();
}

class _HealthReportScreenState extends State<HealthReportScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.health,
      builder: (context, _) {
        final failed = widget.health.failedFor(widget.channels);
        return Scaffold(
          appBar: AppBar(
            title: Text('헬스체크 리포트 (실패 ${failed.length}개)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '전체 재검사',
                onPressed: () => widget.health.checkAll(widget.channels),
              ),
            ],
          ),
          body: widget.health.checking
              ? const Center(child: CircularProgressIndicator())
              : failed.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('모든 채널이 정상입니다'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: failed.length,
                      itemBuilder: (context, index) {
                        final entry = failed[index];
                        final channel = entry.key;
                        final health = entry.value;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: ListTile(
                            leading: channel.logoUrl.isNotEmpty
                                ? Image.network(
                                    channel.logoUrl,
                                    width: 40,
                                    height: 40,
                                    errorBuilder: (_, _, _) =>
                                        const Icon(Icons.tv),
                                  )
                                : const Icon(Icons.tv),
                            title: Text(channel.name),
                            subtitle: Text(
                                '${channel.category} · ${health.message} (${health.latencyMs}ms)'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  tooltip: '테스트 재생',
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TestPlayScreen(channel: channel),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: '재검사',
                                  onPressed: () =>
                                      widget.health.checkChannel(channel),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}