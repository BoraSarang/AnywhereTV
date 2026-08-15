import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anywhere_shared/debug_logger.dart';

class GitHubConfig {
  String token;
  String gistId;
  String gistFilename;

  GitHubConfig({
    this.token = '',
    this.gistId = '949188737a97773ad5313d9cbd159bff',
    this.gistFilename = 'channels.json',
  });

  String get rawUrl =>
      'https://gist.githubusercontent.com/BoraSarang/$gistId/raw/$gistFilename';

  Map<String, dynamic> toJson() =>
      {'token': token, 'gistId': gistId, 'gistFilename': gistFilename};

  static GitHubConfig fromJson(Map<String, dynamic> json) => GitHubConfig(
        token: json['token'] as String? ?? '',
        gistId: json['gistId'] as String? ?? '949188737a97773ad5313d9cbd159bff',
        gistFilename: json['gistFilename'] as String? ?? 'channels.json',
      );
}

class GitHubService {
  static const _configKey = 'github_config';
  static final DebugLogger _log = DebugLogger.instance;

  GitHubConfig _config = GitHubConfig();

  GitHubConfig get config => _config;

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw != null) {
      _config = GitHubConfig.fromJson(jsonDecode(raw));
    }
  }

  Future<void> saveConfig(GitHubConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${_config.token}',
        'Accept': 'application/vnd.github.v3+json',
      };

  Future<String?> fetchFromRawUrl({String? url}) async {
    final uri = Uri.parse(url ?? _config.rawUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return null;
    return response.body;
  }

  Future<bool> uploadToGist(String content, {String? message}) async {
    if (_config.token.isEmpty) {
      _log.warn('Github', '업로드 실패: 토큰이 없습니다');
      return false;
    }
    final url = 'https://api.github.com/gists/${_config.gistId}';
    final body = jsonEncode({
      'description': message ?? 'Update channels',
      'files': {
        _config.gistFilename: {
          'content': content,
        },
      },
    });
    _log.action('Github', 'Gist 업로드 시작: ${_config.gistId}');
    final response =
        await http.patch(Uri.parse(url), headers: _authHeaders, body: body);
    if (response.statusCode == 200) {
      _log.info('Github', 'Gist 업로드 성공 (${response.statusCode})');
      return true;
    }
    _log.error('Github', 'Gist 업로드 실패: HTTP ${response.statusCode} ${response.body}');
    return false;
  }
}
