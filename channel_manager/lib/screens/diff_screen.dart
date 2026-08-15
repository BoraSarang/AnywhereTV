import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/channel.dart';
import '../services/backup_service.dart';
import '../services/channel_store.dart';
import '../services/diff_service.dart';

class DiffScreen extends StatefulWidget {
  final ChannelStore store;

  const DiffScreen({super.key, required this.store});

  @override
  State<DiffScreen> createState() => _DiffScreenState();
}

class _DiffScreenState extends State<DiffScreen> {
  List<File> _backups = [];
  ChannelDiff? _diff;
  String? _selectedBackup;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    final files = await BackupService.listBackups();
    if (!mounted) return;
    setState(() {
      _backups = files;
      if (files.isNotEmpty) {
        _selectedBackup ??= files.first.path;
        _compare(files.first.path);
      }
    });
  }

  Future<void> _compare(String path) async {
    setState(() {
      _loading = true;
      _selectedBackup = path;
    });
    try {
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final oldChannels = (json['channels'] as List<dynamic>?)
              ?.map((e) => Channel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final diff = DiffService.diff(
        oldChannels: oldChannels,
        newChannels: widget.store.channels,
      );
      if (mounted) {
        setState(() => _diff = diff);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 파일을 읽을 수 없습니다: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('백업 비교 (Diff)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '백업 목록 새로고침',
            onPressed: _loadBackups,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: _selectedBackup,
              items: _backups
                  .map((f) => DropdownMenuItem(
                        value: f.path,
                        child: Text(
                          f.path.split('/').last,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) _compare(v);
              },
              decoration: const InputDecoration(
                labelText: '비교할 백업',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _diff == null
                    ? const Center(child: Text('비교할 백업이 없습니다'))
                    : _diff!.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    size: 64, color: Colors.green),
                                SizedBox(height: 16),
                                Text('백업과 현재 상태가 같습니다'),
                              ],
                            ),
                          )
                        : _buildDiffList(_diff!),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffList(ChannelDiff diff) {
    return ListView(
      children: [
        if (diff.added.isNotEmpty) ...[
          _header('추가 (+${diff.added.length})', Colors.green),
          ...diff.added.map((c) => _row(Icons.add_circle, Colors.green, c.name, '카테고리: ${c.category}')),
        ],
        if (diff.removed.isNotEmpty) ...[
          _header('삭제 (-${diff.removed.length})', Colors.red),
          ...diff.removed.map((c) => _row(Icons.remove_circle, Colors.red, c.name, '카테고리: ${c.category}')),
        ],
        if (diff.modified.isNotEmpty) ...[
          _header('수정 (${diff.modified.length})', Colors.blue),
          ...diff.modified.map((m) => _row(
                Icons.edit,
                Colors.blue,
                m.channel.name,
                '변경: ${m.changedFields.join(', ')}',
              )),
        ],
      ],
    );
  }

  Widget _header(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String title, String subtitle) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}