enum AuthProvider {
  email,
  kakao,
  naver,
  google,
  guest,
}

enum MembershipTier {
  free,
  pro,
}

class User {
  String email;
  String name;
  String? password;
  String joinedDate;
  bool isGuest;
  AuthProvider provider;
  String? avatarUrl;
  MembershipTier membership;
  String? lockPin;
  int sendsToday;
  String? lastSendDate;
  String? accessToken;
  String? refreshToken;
  int? lastLoginAt;

  User({
    required this.email,
    required this.name,
    this.password,
    required this.joinedDate,
    this.isGuest = false,
    required this.provider,
    this.avatarUrl,
    required this.membership,
    this.lockPin,
    this.sendsToday = 0,
    this.lastSendDate,
    this.accessToken,
    this.refreshToken,
    this.lastLoginAt,
  });

  User copyWith({
    String? email,
    String? name,
    String? password,
    String? joinedDate,
    bool? isGuest,
    AuthProvider? provider,
    String? avatarUrl,
    MembershipTier? membership,
    String? lockPin,
    int? sendsToday,
    String? lastSendDate,
    String? accessToken,
    String? refreshToken,
    int? lastLoginAt,
  }) {
    return User(
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      joinedDate: joinedDate ?? this.joinedDate,
      isGuest: isGuest ?? this.isGuest,
      provider: provider ?? this.provider,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      membership: membership ?? this.membership,
      lockPin: lockPin ?? this.lockPin,
      sendsToday: sendsToday ?? this.sendsToday,
      lastSendDate: lastSendDate ?? this.lastSendDate,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'password': password,
      'joinedDate': joinedDate,
      'isGuest': isGuest,
      'provider': provider.index,
      'avatarUrl': avatarUrl,
      'membership': membership.index,
      'lockPin': lockPin,
      'sendsToday': sendsToday,
      'lastSendDate': lastSendDate,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'lastLoginAt': lastLoginAt,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      name: json['name'],
      password: json['password'],
      joinedDate: json['joinedDate'],
      isGuest: json['isGuest'] ?? false,
      provider: AuthProvider.values[json['provider'] ?? 0],
      avatarUrl: json['avatarUrl'],
      membership: MembershipTier.values[json['membership'] ?? 0],
      lockPin: json['lockPin'],
      sendsToday: json['sendsToday'] ?? 0,
      lastSendDate: json['lastSendDate'],
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      lastLoginAt: json['lastLoginAt'],
    );
  }
}
