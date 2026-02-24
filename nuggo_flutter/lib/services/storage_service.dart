import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../models/app_settings.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  static const String _keyUsers = 'tapcard_users';
  static const String _keySession = 'tapcard_session';
  static const String _keyAccessToken = 'tapcard_access_token';
  static const String _keyProfiles = 'tapcard_saved_profiles';
  static const String _keySettings = 'tapcard_settings';
  static const String _keyEditorDraft = 'tapcard_editor_draft';
  static const String _keyHasBasicProfile = 'tapcard_has_basic_profile';

  /// getInstance() 한 번만 호출되도록 Future 캐시 (동시 접근 시 데드락 방지)
  Future<SharedPreferences>? _prefsFuture;
  Future<SharedPreferences> _getPrefs() async {
    _prefsFuture ??= SharedPreferences.getInstance();
    return _prefsFuture!;
  }

  // Save Users
  Future<void> saveUsers(List<User> users) async {
    final prefs = await _getPrefs();
    final usersJson = users.map((u) => u.toJson()).toList();
    await prefs.setString(_keyUsers, jsonEncode(usersJson));
  }

  // Get Users
  Future<List<User>> getUsers() async {
    final prefs = await _getPrefs();
    final usersString = prefs.getString(_keyUsers);
    if (usersString == null) return [];
    
    final List<dynamic> usersJson = jsonDecode(usersString);
    return usersJson.map((json) => User.fromJson(json)).toList();
  }

  // Save Session
  Future<void> saveSession(String email, String token) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keySession, email);
    await prefs.setString(_keyAccessToken, token);
  }

  // Get Session
  Future<Map<String, String?>> getSession() async {
    final prefs = await _getPrefs();
    return {
      'email': prefs.getString(_keySession),
      'token': prefs.getString(_keyAccessToken),
    };
  }

  // Clear Session
  Future<void> clearSession() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keySession);
    await prefs.remove(_keyAccessToken);
  }

  // Save Profiles
  Future<void> saveProfiles(List<Profile> profiles) async {
    final prefs = await _getPrefs();
    final profilesJson = profiles.map((p) => p.toJson()).toList();
    await prefs.setString(_keyProfiles, jsonEncode(profilesJson));
  }

  // Get Profiles
  Future<List<Profile>> getProfiles() async {
    final prefs = await _getPrefs();
    final profilesString = prefs.getString(_keyProfiles);
    if (profilesString == null) return [];
    
    final List<dynamic> profilesJson = jsonDecode(profilesString);
    return profilesJson.map((json) => Profile.fromJson(json)).toList();
  }

  // Save Settings
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keySettings, jsonEncode(settings.toJson()));
  }

  // Get Settings
  Future<AppSettings> getSettings() async {
    final prefs = await _getPrefs();
    final settingsString = prefs.getString(_keySettings);
    if (settingsString == null) return AppSettings();
    
    return AppSettings.fromJson(jsonDecode(settingsString));
  }

  // Clear temporary cache data only (preserve account/profiles/settings).
  Future<void> clearTemporaryCache() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyEditorDraft);
  }

  Future<bool> getHasBasicProfile() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_keyHasBasicProfile) ?? false;
  }

  Future<void> setHasBasicProfile(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_keyHasBasicProfile, value);
  }
}
