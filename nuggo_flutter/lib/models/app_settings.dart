enum ProfilePrivacy {
  public,
  linkOnly,
  private,
}

class AppSettings {
  bool darkMode;
  bool notifications;
  bool marketing;
  bool biometrics;
  String systemFont;
  bool sound;
  bool haptic;
  bool privateMode;
  ProfilePrivacy profilePrivacy;
  String language; // 'ko' or 'en'
  bool guestShareTrialUsed; // 게스트 공유/보내기 1회 체험 사용 여부

  AppSettings({
    this.darkMode = true,
    this.notifications = true,
    this.marketing = true,
    this.biometrics = false,
    this.systemFont = 'Manrope',
    this.sound = true,
    this.haptic = true,
    this.privateMode = false,
    this.profilePrivacy = ProfilePrivacy.public,
    this.language = 'ko',
    this.guestShareTrialUsed = false,
  });

  AppSettings copyWith({
    bool? darkMode,
    bool? notifications,
    bool? marketing,
    bool? biometrics,
    String? systemFont,
    bool? sound,
    bool? haptic,
    bool? privateMode,
    ProfilePrivacy? profilePrivacy,
    String? language,
    bool? guestShareTrialUsed,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      notifications: notifications ?? this.notifications,
      marketing: marketing ?? this.marketing,
      biometrics: biometrics ?? this.biometrics,
      systemFont: systemFont ?? this.systemFont,
      sound: sound ?? this.sound,
      haptic: haptic ?? this.haptic,
      privateMode: privateMode ?? this.privateMode,
      profilePrivacy: profilePrivacy ?? this.profilePrivacy,
      language: language ?? this.language,
      guestShareTrialUsed: guestShareTrialUsed ?? this.guestShareTrialUsed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'notifications': notifications,
      'marketing': marketing,
      'biometrics': biometrics,
      'systemFont': systemFont,
      'sound': sound,
      'haptic': haptic,
      'privateMode': privateMode,
      'profilePrivacy': profilePrivacy.index,
      'language': language,
      'guestShareTrialUsed': guestShareTrialUsed,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['darkMode'] ?? false,
      notifications: json['notifications'] ?? true,
      marketing: json['marketing'] ?? true,
      biometrics: json['biometrics'] ?? false,
      systemFont: json['systemFont'] ?? 'Manrope',
      sound: json['sound'] ?? true,
      haptic: json['haptic'] ?? true,
      privateMode: json['privateMode'] ?? false,
      profilePrivacy: ProfilePrivacy.values[json['profilePrivacy'] ?? 0],
      language: json['language'] ?? 'ko',
      guestShareTrialUsed: json['guestShareTrialUsed'] ?? false,
    );
  }
}
