enum FontType {
  serifElegant,
  modernSans,
  playfulScript,
  classicMono,
  editorialItalic,
}

enum ThemeType {
  professional,
  personal,
  creative,
}

class CardData {
  String? profileImage;
  String slogan;
  String fullName;
  String jobTitle;
  String companyName;
  String phone;
  String sms;
  String email;
  String kakao;
  String website;
  String linkedin;
  String shareLink;
  String address;
  String theme;
  FontType font;
  String? portfolioUrl;
  String? portfolioFile; // base64 data URL (data:application/pdf;base64,...)
  String? portfolioFileName; // 원본 파일명 (표시용)

  CardData({
    this.profileImage,
    required this.slogan,
    required this.fullName,
    required this.jobTitle,
    required this.companyName,
    required this.phone,
    required this.sms,
    required this.email,
    required this.kakao,
    required this.website,
    required this.linkedin,
    required this.shareLink,
    required this.address,
    required this.theme,
    required this.font,
    this.portfolioUrl,
    this.portfolioFile,
    this.portfolioFileName,
  });

  static const _undefined = Object();

  CardData copyWith({
    Object? profileImage = _undefined,
    String? slogan,
    String? fullName,
    String? jobTitle,
    String? companyName,
    String? phone,
    String? sms,
    String? email,
    String? kakao,
    String? website,
    String? linkedin,
    String? shareLink,
    String? address,
    String? theme,
    FontType? font,
    String? portfolioUrl,
    String? portfolioFile,
    String? portfolioFileName,
  }) {
    return CardData(
      profileImage: profileImage == _undefined ? this.profileImage : profileImage as String?,
      slogan: slogan ?? this.slogan,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      sms: sms ?? this.sms,
      email: email ?? this.email,
      kakao: kakao ?? this.kakao,
      website: website ?? this.website,
      linkedin: linkedin ?? this.linkedin,
      shareLink: shareLink ?? this.shareLink,
      address: address ?? this.address,
      theme: theme ?? this.theme,
      font: font ?? this.font,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      portfolioFile: portfolioFile ?? this.portfolioFile,
      portfolioFileName: portfolioFileName ?? this.portfolioFileName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileImage': profileImage,
      'slogan': slogan,
      'fullName': fullName,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'phone': phone,
      'sms': sms,
      'email': email,
      'kakao': kakao,
      'website': website,
      'linkedin': linkedin,
      'shareLink': shareLink,
      'address': address,
      'theme': theme,
      'font': font.index,
      'portfolioUrl': portfolioUrl,
      'portfolioFile': portfolioFile,
      'portfolioFileName': portfolioFileName,
    };
  }

  factory CardData.fromJson(Map<String, dynamic> json) {
    return CardData(
      profileImage: json['profileImage'],
      slogan: json['slogan'] ?? '',
      fullName: json['fullName'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      phone: json['phone'] ?? '',
      sms: json['sms'] ?? '',
      email: json['email'] ?? '',
      kakao: json['kakao'] ?? '',
      website: json['website'] ?? '',
      linkedin: json['linkedin'] ?? '',
      shareLink: json['shareLink'] ?? '',
      address: json['address'] ?? '',
      theme: json['theme'] ?? '',
      font: FontType.values[json['font'] ?? 0],
      portfolioUrl: json['portfolioUrl'],
      portfolioFile: json['portfolioFile'],
      portfolioFileName: json['portfolioFileName'],
    );
  }
}
