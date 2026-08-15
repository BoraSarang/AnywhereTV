import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_database.dart';
import '../models/user_state.dart';

class UserStateService {
  static const _keyFavorites = 'favorite_channel_ids';
  static const _keyLastChannel = 'last_watched_channel_id';
  static const _keyResolution = 'preferred_resolution';
  static const _keyVolume = 'last_volume';
  static const _keyTtsEnabled = 'tts_enabled';
  static const _keyBroadcastAlerts = 'broadcast_alerts_enabled';
  static const _keyEpgServerUrl = 'epg_server_url';
  static const _maxHistory = 10;

  SharedPreferences? _prefs;
  AppDatabase? _db;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _db ??= AppDatabase();
  }

  UserState load() {
    if (_prefs == null) return const UserState();
    return UserState(
      favoriteChannelIds: _prefs!.getStringList(_keyFavorites) ?? [],
      lastWatchedChannelId: _prefs!.getString(_keyLastChannel),
      preferredResolution: _prefs!.getString(_keyResolution) ?? '360',
      lastVolume: _prefs!.getDouble(_keyVolume) ?? 0.5,
      ttsEnabled: _prefs!.getBool(_keyTtsEnabled) ?? false,
      broadcastAlertsEnabled: _prefs!.getBool(_keyBroadcastAlerts) ?? false,
      epgServerUrl: _prefs!.getString(_keyEpgServerUrl),
    );
  }

  Future<void> save(UserState state) async {
    await _prefs!.setStringList(_keyFavorites, state.favoriteChannelIds);
    await _prefs!.setString(_keyResolution, state.preferredResolution);
    await _prefs!.setDouble(_keyVolume, state.lastVolume);
    await _prefs!.setBool(_keyTtsEnabled, state.ttsEnabled);
    await _prefs!.setBool(_keyBroadcastAlerts, state.broadcastAlertsEnabled);
    if (state.epgServerUrl != null) {
      await _prefs!.setString(_keyEpgServerUrl, state.epgServerUrl!);
    } else {
      await _prefs!.remove(_keyEpgServerUrl);
    }
    if (state.lastWatchedChannelId != null) {
      await _prefs!.setString(_keyLastChannel, state.lastWatchedChannelId!);
    } else {
      await _prefs!.remove(_keyLastChannel);
    }
  }

  Future<void> setLastChannel(String channelId) async {
    await _prefs!.setString(_keyLastChannel, channelId);
  }

  Future<void> toggleFavorite(String channelId, List<String> currentFavorites) async {
    final updated = currentFavorites.contains(channelId)
        ? currentFavorites.where((id) => id != channelId).toList()
        : [...currentFavorites, channelId];
    await _prefs!.setStringList(_keyFavorites, updated);
  }

  Future<void> setFavoritesOrder(List<String> ids) async {
    await _prefs!.setStringList(_keyFavorites, ids);
  }

  Future<void> setResolution(String resolution) async {
    await _prefs!.setString(_keyResolution, resolution);
  }

  Future<void> setVolume(double volume) async {
    await _prefs!.setDouble(_keyVolume, volume);
  }

  Future<void> setTtsEnabled(bool value) async {
    await _prefs!.setBool(_keyTtsEnabled, value);
  }

  Future<void> setBroadcastAlertsEnabled(bool value) async {
    await _prefs!.setBool(_keyBroadcastAlerts, value);
  }

  Future<void> setEpgServerUrl(String url) async {
    await _prefs!.setString(_keyEpgServerUrl, url);
  }

  Future<List<String>> loadWatchHistory() async {
    final db = _db ??= AppDatabase();
    final ids = await db.loadWatchHistory();
    return ids.take(_maxHistory).toList();
  }

  Future<void> recordWatch(String channelId) async {
    final db = _db ??= AppDatabase();
    await db.recordWatch(channelId);
  }
}
