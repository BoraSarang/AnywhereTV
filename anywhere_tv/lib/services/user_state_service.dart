import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_state.dart';

class UserStateService {
  static const _keyFavorites = 'favorite_channel_ids';
  static const _keyLastChannel = 'last_watched_channel_id';
  static const _keyResolution = 'preferred_resolution';
  static const _keyVolume = 'last_volume';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  UserState load() {
    if (_prefs == null) return const UserState();
    return UserState(
      favoriteChannelIds: _prefs!.getStringList(_keyFavorites) ?? [],
      lastWatchedChannelId: _prefs!.getString(_keyLastChannel),
      preferredResolution: _prefs!.getString(_keyResolution) ?? '360',
      lastVolume: _prefs!.getDouble(_keyVolume) ?? 0.5,
    );
  }

  Future<void> save(UserState state) async {
    await _prefs!.setStringList(_keyFavorites, state.favoriteChannelIds);
    await _prefs!.setString(_keyResolution, state.preferredResolution);
    await _prefs!.setDouble(_keyVolume, state.lastVolume);
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

  Future<void> setResolution(String resolution) async {
    await _prefs!.setString(_keyResolution, resolution);
  }

  Future<void> setVolume(double volume) async {
    await _prefs!.setDouble(_keyVolume, volume);
  }
}
