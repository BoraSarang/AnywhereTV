import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import '../services/ai_assistant_service.dart';
import '../services/channel_store.dart';
import '../services/diff_service.dart';

class AiAssistantScreen extends StatefulWidget {
  final ChannelStore store;

  const AiAssistantScreen({super.key, required this.store});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _apiKey;
  ChannelDiff? _diff;
  Map<String, dynamic>? _newJson;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiKey = prefs.getString('gemini_api_key'));
  }

  Future<void> _send() async {
    final instruction = _controller.text.trim();
    if (instruction.isEmpty) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() => _error = 'E-MAN-AUTH-1001');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _diff = null;
      _newJson = null;
    });
    final result = await AiAssistantService.generateChannelsJson(
      apiKey: _apiKey!,
      currentJson: widget.store.generateJson(),
      instruction: instruction,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'E-MAN-AI-1002';
      });
      return;
    }
    final cleaned = result
        .replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '')
        .trim();
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final newChannels = (json['channels'] as List<dynamic>?)
              ?.map((e) => Channel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final diff = DiffService.diff(
        oldChannels: widget.store.channels,
        newChannels: newChannels,
      );
      setState(() {
        _loading = false;
        _diff = diff;
        _newJson = json;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '응답을 해석하지 못했습니다: $e';
      });
    }
  }

  void _apply() {
    final json = _newJson;
    if (json == null) return;
    final newChannels = (json['channels'] as List<dynamic>?)
            ?.map((e) => Channel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final newCategories = (json['categories'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        [];
    widget.store.applyAiResult(
      channels: newChannels,
      categories: newCategories,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI 변경 사항을 적용했습니다')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 어시스턴트')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '명령 (예: "MBC 채널을 케이블 카테고리로 이동해줘")',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _loading ? null : _send,
                ),
              ),
              onSubmitted: (_) => _loading ? null : _send(),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _error == 'E-MAN-AUTH-1001'
                        ? Icons.key_off
                        : Icons.error_outline,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error == 'E-MAN-AUTH-1001'
                          ? '설정에서 Gemini API 키를 입력해 주세요 (E-MAN-AUTH-1001)'
                          : _error == 'E-MAN-AI-1002'
                              ? 'AI 요청에 실패했습니다. 다시 시도해 주세요 (E-MAN-AI-1002)'
                              : _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _diff == null
                ? const Center(
                    child: Text(
                      '자연어로 채널 목록을 편집할 수 있습니다.\n'
                      '예: "KBS 관련 채널 이름에 KBS 접두어 추가"\n'
                      '    "JTBC를 종편 카테고리로 이동"\n'
                      '    "SBS 채널 삭제"',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _diff!.isEmpty
                    ? const Center(
                        child: Text(
                          '변경 사항이 없습니다. 명령을 다시 입력해 보세요.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildDiffList(_diff!),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() {
                                      _diff = null;
                                      _newJson = null;
                                    }),
                                    child: const Text('취소'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.check),
                                    label: const Text('변경 적용'),
                                    onPressed: _apply,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
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