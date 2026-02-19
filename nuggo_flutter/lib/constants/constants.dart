import '../models/card_data.dart';

class AppConstants {
  /// Gemini API 키 (비어 있으면 AI 추천 대신 기본 슬로건만 사용). 예: --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// 한줄 소개 AI 추천용 기본 슬로건 (API 없을 때 사용)
  static const List<String> defaultSlogans = [
    '당신의 이야기를 한 장에 담다.',
    '연결, 그 이상의 가치.',
    '함께 만드는 다음 이야기.',
    '한 번의 인사가 시작입니다.',
    '소개는 짧게, 인상은 깊게.',
  ];

  // Initial Card Data
  static final CardData initialCardData = CardData(
    slogan: "Your story begins with a single tap.",
    fullName: "Jane Doe",
    jobTitle: "Creative Director",
    companyName: "The Studio Inc.",
    phone: "+1 234 567 890",
    sms: "+1 234 567 890",
    email: "jane@thestudio.com",
    kakao: "janedoe_studio",
    website: "www.yourportfolio.com",
    linkedin: "linkedin.com/in/janedoe",
    shareLink: "nuggo.me/janedoe",
    address: "123 Creative Ave, New York, NY",
    theme: 'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&q=80&w=400',
    font: FontType.serifElegant,
  );

  // Theme Templates (via.placeholder.com 제외 - CORS 문제로 Unsplash만 사용)
  static const Map<ThemeType, List<String>> themeTemplates = {
    ThemeType.professional: [
      'https://images.unsplash.com/photo-1541701494587-cb58502866ab?auto=format&fit=crop&q=80&w=400',
      'https://images.unsplash.com/photo-1634017839464-5c339ebe3cb4?auto=format&fit=crop&q=80&w=400',
      'https://images.unsplash.com/photo-1557683316-973673baf926?auto=format&fit=crop&q=80&w=400',
    ],
    ThemeType.personal: [
      '#F3EFE4',
      '#CD5C45',
      '#2563EB',
    ],
    ThemeType.creative: [
      'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&q=80&w=400',
      'https://images.unsplash.com/photo-1558591710-4b4a1ae0f04d?auto=format&fit=crop&q=80&w=400', // 크리에이티브 가운데 - 아트 스타일
      'https://images.unsplash.com/photo-1502691876148-a84978e59af8?auto=format&fit=crop&q=80&w=400',
    ],
  };

  // Font Configs
  static const Map<FontType, Map<String, String>> fontConfigs = {
    FontType.serifElegant: {
      'name': 'Serif Elegant',
      'subtitle': 'Timeless & Professional',
    },
    FontType.modernSans: {
      'name': 'Modern Sans',
      'subtitle': 'Clean & Geometric',
    },
    FontType.playfulScript: {
      'name': 'Playful Script',
      'subtitle': 'Personal & Warm',
    },
    FontType.classicMono: {
      'name': 'Classic Mono',
      'subtitle': 'Technical & Precise',
    },
    FontType.editorialItalic: {
      'name': 'Editorial Italic',
      'subtitle': 'Expressive & Bold',
    },
  };

  // Legal Texts
  static const String termsOfService = '''
NUGGO 이용약관

제1조 (목적)
이 약관은 NUGGO(이하 "회사")가 제공하는 디지털 명함 서비스(이하 "서비스")의 이용과 관련하여 회사와 회원 간의 권리·의무 및 책임사항을 규정함을 목적으로 합니다.

제2조 (정의)
"서비스"란 회사가 제공하는 NUGGO 모바일 애플리케이션 및 관련 제반 서비스를 말합니다.
"회원"이란 본 약관에 동의하고 서비스를 이용하는 자를 말합니다.
"유료서비스"란 구독 결제를 통해 이용 가능한 프리미엄 기능을 말합니다.

제3조 (약관의 게시 및 개정)
회사는 본 약관을 서비스 내 초기화면 또는 설정 화면에 게시합니다.
회사는 관련 법령을 위배하지 않는 범위에서 약관을 개정할 수 있으며, 개정 시 사전 공지합니다.
회원이 개정 약관에 동의하지 않을 경우 이용을 중단하고 탈퇴할 수 있습니다.

제4조 (서비스의 제공)
회사는 다음과 같은 서비스를 제공합니다.
1. 디지털 명함 생성·편집·공유 기능
2. 이미지 업로드 및 배경 디자인 기능
3. NFC 연동 및 사용 가이드
4. 기타 회사가 추가 개발하거나 제휴로 제공하는 서비스

[... 추가 내용 생략 ...]
''';

  static const String privacyPolicy = '''
NUGGO 개인정보처리방침

NUGGO(이하 "회사")는 「개인정보 보호법」 등 관련 법령을 준수하며, 이용자의 개인정보를 중요하게 보호하고 있습니다.

1. 개인정보의 처리 목적
회사는 다음의 목적을 위하여 개인정보를 처리합니다.
- 회원 가입 및 관리: 본인 확인, 회원 식별 및 부정 이용 방지
- 서비스 제공 및 계약 이행: 디지털 명함 생성 및 관리, NFC 연동 기능 제공
- 고객 상담 및 민원 처리: 문의 응대, 불만 및 고충 처리

[... 추가 내용 생략 ...]
''';
}
