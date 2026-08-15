import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/channel.dart';
import 'package:anywhere_shared/debug_logger.dart';

class ChannelRepository {
  static const _cacheKey = 'cached_channels_data';
  final DebugLogger _log = DebugLogger.instance;

  List<Channel> _channels = [];
  List<Channel> get channels => List.unmodifiable(_channels);
  int _currentVersion = 0;
  int get currentVersion => _currentVersion;
  String _remoteUrl = '';
  VoidCallback? onChannelsUpdated;

  Future<void> init() async {
    // 1. 앱 번들 assets/channels.json 로드
    await _loadFromBundle();
    if (_channels.isEmpty) {
      _log.error('ChannelRepo', 'No channels from bundle');
      return;
    }

    // 2. SharedPreferences 캐시 로드
    await _loadFromCache();

    // 3. 백그라운드에서 Remote fetch
    _fetchRemote();
  }

  Future<void> _loadFromBundle() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/channels.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      _currentVersion = data['version'] as int? ?? 0;
      _remoteUrl = data['remoteUrl'] as String? ?? '';
      final list = data['channels'] as List<dynamic>;
      _channels = list.map((e) => Channel.fromJson(e as Map<String, dynamic>)).toList();
      _log.system('ChannelRepo', 'bundle v$_currentVersion: ${_channels.length} channels');
    } catch (e) {
      _log.error('ChannelRepo', 'bundle load failed: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached == null) return;
      final data = json.decode(cached) as Map<String, dynamic>;
      final cachedVersion = data['version'] as int? ?? 0;
      final channelsRaw = data['channels'] as List<dynamic>?;
      if (channelsRaw == null || channelsRaw.isEmpty) return;
      if (cachedVersion < _currentVersion) return; // 캐시가 더 오래됨
      _channels = channelsRaw.map((e) => Channel.fromJson(e as Map<String, dynamic>)).toList();
      _currentVersion = cachedVersion;
      _log.system('ChannelRepo', 'cache v$_currentVersion loaded');
    } catch (e) {
      _log.warn('ChannelRepo', 'cache load failed: $e');
    }
  }

  Future<void> _fetchRemote() async {
    if (_remoteUrl.isEmpty) return;
    try {
      final response = await http.get(Uri.parse(_remoteUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final data = json.decode(response.body) as Map<String, dynamic>;
      final remoteVersion = data['version'] as int? ?? 0;
      if (remoteVersion <= _currentVersion) return; // 최신 버전
      final list = data['channels'] as List<dynamic>;
      final channels = list.map((e) => Channel.fromJson(e as Map<String, dynamic>)).toList();
      if (channels.isEmpty) return;

      _channels = channels;
      _currentVersion = remoteVersion;
      _remoteUrl = data['remoteUrl'] as String? ?? _remoteUrl;

      // 캐시 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, response.body);
      _log.system('ChannelRepo', 'remote v$remoteVersion: ${channels.length} channels updated');
      onChannelsUpdated?.call();
    } catch (e) {
      _log.warn('ChannelRepo', 'remote fetch failed: $e');
    }
  }

  Future<bool> checkForUpdates() async {
    final oldVersion = _currentVersion;
    await _fetchRemote();
    return _currentVersion > oldVersion;
  }

  Channel? getById(String id) {
    try {
      return _channels.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Channel> getByCategory(String category) {
    return _channels.where((c) => c.category == category).toList();
  }

  List<Channel> get defaultFavorites {
    return _channels.where((c) => c.isDefaultFavorite).toList();
  }
}
