import 'dart:async';

import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/profile.dart';
import '../models/card_data.dart';
import '../models/app_settings.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../constants/constants.dart';

enum ViewType { editor, preview, myCards, wallet, account, settings }

class AppProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  Timer? _cardDataNotifyDebounce;

  // Auth & Session
  User? _currentUser;
  final bool _isLoadingSession = false;
  bool _isAppLocked = false;
  bool _isPinSetupMode = false;

  // Navigation
  ViewType _activeView = ViewType.myCards;
  ViewType? _previousView;

  // App Settings
  AppSettings _settings = AppSettings();

  // Card & Profile Data (기본값으로 앱 즉시 표시, 저장소는 백그라운드 로드)
  final Map<String, CardData> _cardsMap = {};
  String _activeThemeUrl = AppConstants.initialCardData.theme;
  List<Profile> _savedProfiles = [];
  String? _activeProfileId;
  String? _selectedProfileId;
  Profile? _lastDeletedProfile;

  // Payment Modal
  bool _isPaymentModalOpen = false;

  /// 다음 에디터 빌드 시 배경 테마 섹션으로 스크롤 요청 (내 명함에서 프로필 추가 후 에디터로 이동 시 사용)
  bool _scrollToBackgroundThemeOnNextBuild = false;

  // Display Mode (임시: 폰/PC 모드 구분용)
  bool _isPhoneFrameMode = true;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoadingSession => _isLoadingSession;
  bool get isAppLocked => _isAppLocked;
  bool get isPinSetupMode => _isPinSetupMode;
  ViewType get activeView => _activeView;
  ViewType? get previousView => _previousView;
  AppSettings get settings => _settings;
  CardData get currentCardData =>
      _cardsMap[_activeThemeUrl] ??
      AppConstants.initialCardData.copyWith(theme: _activeThemeUrl);
  List<Profile> get savedProfiles => _savedProfiles;
  String? get activeProfileId => _activeProfileId;
  String? get selectedProfileId => _selectedProfileId;
  Profile? get selectedProfile {
    if (_selectedProfileId == null) return null;
    for (final p in _savedProfiles) {
      if (p.id == _selectedProfileId) return p;
    }
    return null;
  }

  bool get isPaymentModalOpen => _isPaymentModalOpen;
  bool get canRestoreProfile => _lastDeletedProfile != null;
  bool get scrollToBackgroundThemeOnNextBuild =>
      _scrollToBackgroundThemeOnNextBuild;
  bool get isPro => _currentUser?.membership == MembershipTier.pro;
  bool get isPhoneFrameMode => _isPhoneFrameMode;

  void requestScrollToBackgroundTheme() {
    _scrollToBackgroundThemeOnNextBuild = true;
    notifyListeners();
  }

  void consumeScrollToBackgroundTheme() {
    _scrollToBackgroundThemeOnNextBuild = false;
  }

  /// 앱을 블로킹하지 않고 백그라운드에서 설정·프로필 로드 (첫 화면 즉시 표시)
  void initialize() {
    _cardsMap[_activeThemeUrl] = AppConstants.initialCardData;
    _savedProfiles.add(
      Profile(
        id: 'default_0',
        name: 'My Card',
        data: AppConstants.initialCardData,
      ),
    );
    _activeProfileId = 'default_0';
    unawaited(_loadFromStorage());
  }

  Future<void> _loadFromStorage() async {
    final results = await Future.wait([
      _storage.getSettings(),
      _storage.getProfiles(),
    ]);
    _settings = results[0] as AppSettings;
    _savedProfiles = results[1] as List<Profile>;

    if (_savedProfiles.isEmpty) {
      _savedProfiles.add(
        Profile(
          id: 'default_${DateTime.now().millisecondsSinceEpoch}',
          name: 'My Card',
          data: AppConstants.initialCardData,
        ),
      );
      unawaited(_storage.saveProfiles(_savedProfiles));
    }
    _cardsMap[_activeThemeUrl] = AppConstants.initialCardData;
    if (_savedProfiles.isNotEmpty) {
      final first = _savedProfiles.first;
      _cardsMap[first.data.theme] = first.data;
      _activeThemeUrl = first.data.theme;
      _activeProfileId = first.id;
    }
    notifyListeners();
    unawaited(_restoreSession());
  }

  Future<void> _restoreSession() async {
    final user = await _authService.restoreSession();
    if (user != null) {
      _currentUser = user;
      if (_settings.biometrics && user.lockPin != null) _isAppLocked = true;
    } else {
      await _loginAsGuest();
    }
    notifyListeners();
  }

  // Auth Methods
  Future<void> _loginAsGuest() async {
    _currentUser = await _authService.loginAsGuest();
    notifyListeners();
  }

  Future<void> handleAuth({
    required String type, // 'guest', 'email', 'social'
    String? email,
    String? password,
    String? name,
    bool isSignUp = false,
    AuthProvider? provider,
    String? avatarUrl,
  }) async {
    try {
      if (type == 'guest') {
        await _loginAsGuest();
        return;
      }

      if (type == 'email') {
        if (isSignUp) {
          _currentUser = await _authService.signUpWithEmail(
            email!,
            password!,
            name ?? email.split('@')[0],
          );
        } else {
          _currentUser = await _authService.loginWithEmail(email!, password!);
        }
      } else if (type == 'social') {
        _currentUser = await _authService.loginWithSocial(
          email!,
          name!,
          provider!,
          avatarUrl: avatarUrl,
        );
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _loginAsGuest();
    _activeView = ViewType.myCards;
    _isAppLocked = false;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_currentUser == null) return;
    await _authService.deleteAccount(_currentUser!.email);
    await logout();
  }

  Future<void> updateUser(User user) async {
    _currentUser = user;
    if (!user.isGuest) {
      await _authService.updateUser(user);
    }
    notifyListeners();
  }

  Future<void> updateCurrentUserProfile({
    required String name,
    required String email,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    final previousEmail = _currentUser!.email;
    final normalizedPhone = (phoneNumber ?? '').trim();
    final updated = _currentUser!.copyWith(
      name: name.trim(),
      email: email.trim(),
      phoneNumber: normalizedPhone.isEmpty ? null : normalizedPhone,
      avatarUrl: avatarUrl,
    );
    _currentUser = updated;

    if (!updated.isGuest) {
      if (updated.email == previousEmail) {
        await _authService.updateUser(updated);
      } else {
        final users = await _storage.getUsers();
        final idx = users.indexWhere((u) => u.email == previousEmail);
        if (idx != -1) {
          users[idx] = updated;
          await _storage.saveUsers(users);
        }
        final session = await _storage.getSession();
        final sessionEmail = session['email'];
        final token =
            session['token'] ?? updated.accessToken ?? _currentUser!.accessToken;
        if (sessionEmail == previousEmail && token != null) {
          await _storage.saveSession(updated.email, token);
        }
      }
    }
    notifyListeners();
  }

  // Settings Methods
  /// [notify] false: 메인 화면에 미표시 항목(사운드/햅틱 등) 업데이트 시 리빌드 생략
  Future<void> updateSettings(AppSettings newSettings, {bool notify = true}) async {
    _settings = newSettings;
    unawaited(_storage.saveSettings(_settings));
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await updateSettings(_settings.copyWith(notifications: enabled));
  }

  Future<void> setAppLanguage(String language) async {
    if (language != 'ko' && language != 'en') return;
    await updateSettings(_settings.copyWith(language: language));
  }

  Future<void> clearTemporaryCache() async {
    await _storage.clearTemporaryCache();
  }

  void _notifyNow() {
    _cardDataNotifyDebounce?.cancel();
    notifyListeners();
  }

  void _notifyCardDataDebounced() {
    _cardDataNotifyDebounce?.cancel();
    _cardDataNotifyDebounce = Timer(const Duration(milliseconds: 30), () {
      notifyListeners();
    });
  }

  // Card Data Methods
  void updateCardData(
    CardData newData, {
    bool notify = true,
    bool immediate = false,
  }) {
    final theme = newData.theme;
    _cardsMap[theme] = newData;

    if (theme != _activeThemeUrl) {
      _activeThemeUrl = theme;
    }

    if (!notify) return;
    if (immediate) {
      _notifyNow();
    } else {
      _notifyCardDataDebounced();
    }
  }

  // Profile Methods
  Future<void> saveProfile(Profile profile) async {
    final exists = _savedProfiles.any((p) => p.id == profile.id);

    if (exists) {
      _savedProfiles = _savedProfiles
          .map((p) => p.id == profile.id ? profile : p)
          .toList();
    } else {
      _savedProfiles.add(profile);
    }

    _activeProfileId = profile.id;
    await _storage.saveProfiles(_savedProfiles);
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    Profile? removed;
    for (final p in _savedProfiles) {
      if (p.id == id) {
        removed = p;
        break;
      }
    }
    if (removed != null) _lastDeletedProfile = removed;

    if (_selectedProfileId == id) _selectedProfileId = null;
    _savedProfiles.removeWhere((p) => p.id == id);

    // Ensure at least one profile
    if (_savedProfiles.isEmpty) {
      _savedProfiles.add(
        Profile(
          id: 'default_${DateTime.now().millisecondsSinceEpoch}',
          name: 'My Card',
          data: AppConstants.initialCardData,
        ),
      );
    }

    if (_activeProfileId == id) {
      _activeProfileId = null;
    }

    await _storage.saveProfiles(_savedProfiles);
    notifyListeners();
  }

  Future<void> restoreLastDeletedProfile() async {
    if (_lastDeletedProfile == null) return;
    _savedProfiles.add(_lastDeletedProfile!);
    _lastDeletedProfile = null;
    await _storage.saveProfiles(_savedProfiles);
    notifyListeners();
  }

  void loadProfile(Profile profile) {
    updateCardData(profile.data, notify: false);
    _activeProfileId = profile.id;
    _notifyNow();
  }

  void createNewProfile() {
    // 결제/프로필 제한은 나중에 설정 예정. 일단 제한 없이 새 프로필 생성.
    // if (!isPro && _savedProfiles.length >= 2) {
    //   _isPaymentModalOpen = true;
    //   notifyListeners();
    //   return;
    // }

    final defaultTheme = AppConstants.initialCardData.theme;
    _activeThemeUrl = defaultTheme;
    _cardsMap.clear();
    _cardsMap[defaultTheme] = AppConstants.initialCardData;
    _activeProfileId = null;
    notifyListeners();
  }

  // Navigation
  void setActiveView(ViewType view) {
    if (view == _activeView) return;
    _previousView = _activeView;
    _activeView = view;
    if (view == ViewType.myCards) {
      final valid =
          _selectedProfileId != null &&
          _savedProfiles.any((p) => p.id == _selectedProfileId);
      if (!valid && _savedProfiles.isNotEmpty) {
        _selectedProfileId = _savedProfiles.first.id;
      }
    }
    notifyListeners();
  }

  /// 내 명함에서 프로필 선택
  void selectProfile(String? profileId) {
    if (_selectedProfileId == profileId) return;
    _selectedProfileId = profileId;
    notifyListeners();
  }

  void clearSelectedProfile() {
    _selectedProfileId = null;
    notifyListeners();
  }

  // App Lock
  void unlockApp() {
    _isAppLocked = false;
    notifyListeners();
  }

  void setPinSetupMode(bool mode) {
    _isPinSetupMode = mode;
    notifyListeners();
  }

  Future<void> setupPin(String pin) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(lockPin: pin);
      await updateUser(updatedUser);

      final updatedSettings = _settings.copyWith(biometrics: true);
      await updateSettings(updatedSettings);
    }
    _isPinSetupMode = false;
    notifyListeners();
  }

  // Display Mode (임시)
  void setPhoneFrameMode(bool value) {
    _isPhoneFrameMode = value;
    notifyListeners();
  }

  // Payment Modal
  void setPaymentModalOpen(bool open) {
    _isPaymentModalOpen = open;
    notifyListeners();
  }

  Future<void> upgradeToPro() async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(
        membership: MembershipTier.pro,
      );
      await updateUser(updatedUser);
    }
    notifyListeners();
  }

  // Send Count
  void incrementSendCount() {
    if (_currentUser == null ||
        _currentUser!.membership == MembershipTier.pro) {
      return;
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    int count = _currentUser!.sendsToday;

    if (_currentUser!.lastSendDate != today) {
      count = 0;
    }

    final updatedUser = _currentUser!.copyWith(
      sendsToday: count + 1,
      lastSendDate: today,
    );

    updateUser(updatedUser);
  }

  @override
  void dispose() {
    _cardDataNotifyDebounce?.cancel();
    super.dispose();
  }
}
