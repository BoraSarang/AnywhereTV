import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/logo_service.dart';
import '../services/ai_search_service.dart';
import '../services/youtube_meta_service.dart';
import 'package:anywhere_shared/debug_logger.dart';

class LogoSearchResult {
  final String logoUrl;
  final String? name;
  final String? handle;
  final String? channelId;

  const LogoSearchResult({
    required this.logoUrl,
    this.name,
    this.handle,
    this.channelId,
  });
}

Future<LogoSearchResult?> showLogoSearchDialog(
  BuildContext context,
  String query,
) {
  return showDialog<LogoSearchResult>(
    context: context,
    builder: (_) => _LogoSearchDialog(query: query),
  );
}

class _LogoSearchDialog extends StatefulWidget {
  final String query;

  const _LogoSearchDialog({required this.query});

  @override
  State<_LogoSearchDialog> createState() => _LogoSearchDialogState();
}

class _LogoSearchDialogState extends State<_LogoSearchDialog> {
  static final DebugLogger _log = DebugLogger.instance;
  List<LogoCandidate> _iptvResults = [];
  List<AiChannelCandidate> _aiResults = [];
  bool _loadingIptv = true;
  bool _loadingAi = false;
  bool _selecting = false;
  String? _error;
  String? _apiKey;
  int? _hoveredAi;
  int? _hoveredIptv;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _loadIptv();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _apiKey = prefs.getString('gemini_api_key'));
  }

  Future<void> _loadIptv() async {
    setState(() {
      _loadingIptv = true;
      _error = null;
    });
    final results = await LogoService.search(widget.query);
    if (!mounted) return;
    setState(() {
      _iptvResults = results;
      _loadingIptv = false;
    });
  }

  Future<void> _aiSearch() async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      setState(() => _error = 'E-MAN-AUTH-1001');
      return;
    }
    setState(() {
      _loadingAi = true;
      _error = null;
      _aiResults = [];
    });
    final (results, status) = await AiSearchService.searchChannels(
      apiKey: _apiKey!,
      query: '${widget.query} 라이브 채널',
    );
    if (!mounted) return;
    setState(() {
      _loadingAi = false;
      if (status == 429 || status == 403) {
        _error = 'E-MAN-AI-1005';
        _aiResults = [];
      } else {
        _aiResults = results ?? [];
        if (results == null) _error = 'E-MAN-AI-1003';
      }
    });
  }

  Future<void> _selectCandidate(AiChannelCandidate candidate) async {
    setState(() => _selecting = true);
    String? logoUrl = candidate.logoUrl;
    String? name = candidate.name;
    String? handle;
    String? channelId;

    final url = candidate.channelUrl ?? '';
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      final meta = await YoutubeMetaService.fetch(url);
      if (meta != null) {
        logoUrl = meta.avatarUrl ?? logoUrl;
        name = meta.name.isEmpty ? name : meta.name;
        handle = meta.handle;
        channelId = meta.channelId;
      }
    }
    if (!mounted) return;
    if (logoUrl == null || logoUrl.isEmpty) {
      setState(() => _selecting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('썸네일(로고) 정보가 없습니다. 다른 후보를 선택해 주세요.')),
      );
      return;
    }
    _log.info('AI', '로고 선택: $name (${handle ?? channelId ?? 'no-meta'})');
    Navigator.pop(
      context,
      LogoSearchResult(logoUrl: logoUrl, name: name, handle: handle, channelId: channelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('로고 검색: ${widget.query}'),
      content: SizedBox(
        width: 480,
        height: 440,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('이름 검색'),
                  onPressed: _loadingIptv ? null : _loadIptv,
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: _loadingAi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('AI 검색 (웹)'),
                  onPressed: _loadingAi ? null : _aiSearch,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'AI 선택 시 로고·이름·핸들 자동 입력',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      _error == 'E-MAN-AUTH-1001' ? Icons.key_off : Icons.error_outline,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error == 'E-MAN-AUTH-1001'
                            ? '설정에서 Gemini API 키를 입력해 주세요 (E-MAN-AUTH-1001)'
                            : _error == 'E-MAN-AI-1005'
                                ? 'Gemini API 할당량을 초과했습니다. 잠시 후 다시 시도하거나 AI Studio에서 플랜을 확인해 주세요 (E-MAN-AI-1005)'
                                : _error == 'E-MAN-AI-1003'
                                    ? 'AI 검색 결과를 해석하지 못했습니다. 다시 시도해 주세요 (E-MAN-AI-1003)'
                                    : _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _selecting
                  ? const Center(child: CircularProgressIndicator())
                  : _loadingAi
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('웹 검색 중... (최대 30초)',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : _aiResults.isNotEmpty
                          ? ListView.builder(
                              itemCount: _aiResults.length,
                              itemBuilder: (context, index) {
                                final c = _aiResults[index];
                                return MouseRegion(
                                  onEnter: (_) =>
                                      setState(() => _hoveredAi = index),
                                  onExit: (_) => setState(() => _hoveredAi = null),
                                  child: ListTile(
                                    dense: true,
                                    visualDensity:
                                        const VisualDensity(vertical: -4),
                                    tileColor: _hoveredAi == index
                                        ? Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                        : null,
                                    leading: c.logoUrl != null && c.logoUrl!.isNotEmpty
                                        ? Image.network(
                                            c.logoUrl!,
                                            width: 32,
                                            height: 32,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(Icons.live_tv),
                                          )
                                        : const Icon(Icons.live_tv),
                                    title: Text(c.name,
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    subtitle: c.description.isNotEmpty
                                        ? Text(c.description,
                                            maxLines: 1, overflow: TextOverflow.ellipsis)
                                        : null,
                                    trailing: c.platform != null
                                        ? Text(c.platform!,
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.blueGrey))
                                        : null,
                                    onTap: () => _selectCandidate(c),
                                  ),
                                );
                              },
                            )
                          : _loadingIptv
                              ? const Center(child: CircularProgressIndicator())
                              : _iptvResults.isEmpty
                                  ? const Center(child: Text('일치하는 채널을 찾지 못했습니다.'))
                                  : ListView.builder(
                                      itemCount: _iptvResults.length,
                                      itemBuilder: (context, index) {
                                        final candidate = _iptvResults[index];
                                        return MouseRegion(
                                          onEnter: (_) =>
                                              setState(() => _hoveredIptv = index),
                                          onExit: (_) =>
                                              setState(() => _hoveredIptv = null),
                                          child: ListTile(
                                            dense: true,
                                            visualDensity:
                                                const VisualDensity(vertical: -4),
                                            tileColor: _hoveredIptv == index
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                : null,
                                            leading: Image.network(
                                              candidate.logoUrl,
                                              width: 32,
                                              height: 32,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(Icons.image_not_supported),
                                            ),
                                            title: Text(candidate.name),
                                            onTap: () => Navigator.pop(
                                              context,
                                              LogoSearchResult(
                                                logoUrl: candidate.logoUrl,
                                                name: candidate.name,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
