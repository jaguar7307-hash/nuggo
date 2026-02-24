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
시행일: 2025년 1월 1일

NUGGO(이하 "회사")는 「개인정보 보호법」 제30조 및 개인정보보호위원회 「개인정보 처리방침 작성지침」에 따라 이용자의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 하기 위하여 다음과 같이 개인정보 처리방침을 수립·공개합니다.

1. 개인정보의 처리 목적
회사는 다음의 목적을 위하여 개인정보를 처리합니다.
• 회원 가입 및 관리: 본인 확인, 회원 식별, 부정 이용 방지, 서비스 부가 기능 제공
• 서비스 제공 및 계약 이행: 디지털 명함 생성·편집·관리, 프로필 이미지·연락처 저장, NFC 연동 기능 제공
• 고객 상담 및 민원 처리: 문의 응대, 불만 및 고충 처리
• 마케팅 및 광고: 서비스 개선, 이벤트 및 프로모션 안내 (동의 시에 한함)

2. 수집하는 개인정보의 항목
[필수] 이메일, 비밀번호, 이름, 전화번호, 프로필 이미지
[선택] 직함/직책, 회사/소속, 카카오톡 ID, 웹사이트 URL, 주소, 포트폴리오 파일
[자동] 기기 정보, 앱 사용 기록 (서비스 최적화·오류 분석 목적)

3. 개인정보의 보유 및 이용 기간
• 회원 정보: 회원 탈퇴 시까지 (법령에 따라 보존 필요 시 해당 기간 보관)
• 명함 데이터: 회원 탈퇴 시까지 (로컬 저장 데이터는 앱 삭제 시 함께 삭제)
• 고객 문의 기록: 문의 처리 완료 후 3년

4. 개인정보의 제3자 제공
회사는 이용자의 개인정보를 원칙적으로 제3자에게 제공하지 않습니다. 다만, 이용자가 사전에 동의한 경우 또는 법령에 따른 수사기관의 요구가 있는 경우에는 예외로 합니다.

5. 개인정보 처리의 위탁
회사는 원활한 서비스 제공을 위해 필요한 경우 개인정보 처리 업무를 외부에 위탁할 수 있으며, 위탁 시 위탁받는 자, 위탁 업무 내용, 위탁 기간 등을 이용자에게 고지합니다.

6. 정보주체의 권리·의무 및 행사 방법
이용자는 개인정보 열람·정정·삭제·처리정지 요구 권리를 행사할 수 있으며, 서비스 내 설정 메뉴 또는 고객센터를 통해 요청할 수 있습니다. 회사는 이에 대해 지체 없이 조치하겠습니다.

7. 개인정보의 안전성 확보 조치
회사는 개인정보의 암호화, 해킹 등에 대비한 기술적 대책, 접근 제한, 처리 직원 최소화 및 교육 등 필요한 조치를 취하고 있습니다.

8. 개인정보 처리방침의 변경
이 개인정보 처리방침은 법령 및 방침에 따라 변경될 수 있으며, 변경 시 앱 내 공지사항 또는 서비스 초기화면을 통해 공지합니다.

9. 개인정보 보호책임자
회사는 개인정보 처리에 관한 업무를 총괄하여 책임지고, 이용자의 불만 처리 및 피해 구제를 위하여 개인정보 보호책임자를 지정·운영합니다. (담당자 지정 시 연락처 기재)

10. 권익침해 구제방법
• 개인정보분쟁조정위원회: (국번없이) 1833-6972, www.kopico.go.kr
• 개인정보침해신고센터: (국번없이) 118, privacy.kisa.or.kr
• 대검찰청 사이버수사과: (국번없이) 1301
• 경찰청 사이버안전국: (국번없이) 182

본 개인정보처리방침은 2025년 1월 1일부터 시행됩니다.
''';
}
