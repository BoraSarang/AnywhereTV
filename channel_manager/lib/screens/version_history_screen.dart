import 'package:flutter/material.dart';
import '../services/channel_store.dart';
import 'diff_screen.dart';

class VersionHistoryScreen extends StatelessWidget {
  final ChannelStore store;
  const VersionHistoryScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('버전 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: '백업 비교',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DiffScreen(store: store)),
            ),
          ),
        ],
      ),
      body: store.history.isEmpty
          ? const Center(child: Text('기록 없음'))
          : ListView.builder(
              itemCount: store.history.length,
              itemBuilder: (context, index) {
                final entry = store.history[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('v${entry.version}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            Text(entry.date, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...entry.changes.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Row(
                            children: [
                              if (c.startsWith('add'))
                                const Icon(Icons.add_circle, size: 14, color: Colors.green)
                              else if (c.startsWith('remove'))
                                const Icon(Icons.remove_circle, size: 14, color: Colors.red)
                              else
                                const Icon(Icons.edit, size: 14, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text(c),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
