# NUGGO - 디지털 명함 앱 (Flutter)

React 프로젝트를 Flutter로 완전히 변환한 디지털 명함 제작 및 관리 애플리케이션입니다.

## 주요 기능

### ✨ 명함 생성 및 편집
- 실시간 미리보기
- 다양한 배경 테마 (Professional, Personal, Creative)
- 폰트 선택 (5가지 폰트 스타일)
- 프로필 이미지 업로드
- 명함 정보 입력 (이름, 직함, 회사, 연락처 등)

### 📱 명함 공유
- QR 코드 생성
- NFC 태그 쓰기
- 링크 공유
- 명함 전송

### 💾 프로필 관리
- 여러 프로필 저장 및 관리
- 프로필 불러오기
- 프로필 삭제
- Free 사용자: 최대 2개 프로필
- Pro 사용자: 무제한 프로필

### 👤 사용자 인증
- 게스트 모드
- 이메일 로그인/회원가입
- 소셜 로그인 (Kakao, Naver, Google)
- 세션 관리

### 🔐 보안
- PIN 코드 잠금
- 생체 인증
- 자동 로그아웃

### ⚙️ 설정
- 다크 모드
- 알림 설정
- 언어 설정 (한국어/영어)
- 시스템 폰트 선택

### 💳 멤버십
- Free: 기본 기능
- Pro: 
  - 무제한 프로필
  - 이미지 업로드
  - AI 기능 (슬로건/배경 생성)
  - 포트폴리오 링크

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── models/                   # 데이터 모델
│   ├── card_data.dart
│   ├── user.dart
│   ├── profile.dart
│   └── app_settings.dart
├── providers/                # 상태 관리 (Provider)
│   └── app_provider.dart
├── screens/                  # 화면
│   ├── editor_screen.dart
│   ├── preview_screen.dart
│   ├── profile_screen.dart
│   ├── wallet_screen.dart
│   ├── account_screen.dart
│   └── settings_screen.dart
├── widgets/                  # 재사용 가능한 위젯
│   ├── digital_card.dart
│   ├── bottom_nav.dart
│   └── header.dart
├── services/                 # 서비스 레이어
│   ├── storage_service.dart
│   └── auth_service.dart
├── constants/                # 상수
│   ├── constants.dart
│   └── theme.dart
└── utils/                    # 유틸리티
```

## 사용된 패키지

- **provider**: 상태 관리
- **shared_preferences**: 로컬 저장소
- **image_picker**: 이미지 선택
- **image_cropper**: 이미지 크롭
- **qr_flutter**: QR 코드 생성
- **nfc_manager**: NFC 기능
- **google_fonts**: 폰트
- **url_launcher**: URL 열기
- **share_plus**: 공유 기능
- **local_auth**: 생체 인증
- **google_generative_ai**: AI 기능 (Gemini)

## 설치 및 실행

### 요구사항
- Flutter SDK 3.38.9 이상
- Dart 3.10.8 이상

### 설치

```bash
# 의존성 설치
cd nuggo_flutter
flutter pub get

# 앱 실행
flutter run
```

### 빌드

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Windows
flutter build windows --release
```

## 개발 참고사항

### Windows에서 개발 시
플러그인을 사용하려면 개발자 모드를 활성화해야 합니다:
```powershell
start ms-settings:developers
```

### AI 기능 사용
Google Gemini API 키가 필요합니다. `.env` 파일에 API 키를 추가하세요.

## React 프로젝트와의 차이점

### 상태 관리
- React: useState, useCallback, useMemo
- Flutter: Provider (ChangeNotifier)

### 스타일링
- React: Tailwind CSS
- Flutter: Material Design 3 + Custom Theme

### 라우팅
- React: 단일 페이지 (View 상태로 화면 전환)
- Flutter: 동일한 방식 유지 (ViewType enum으로 화면 전환)

### 로컬 저장소
- React: localStorage
- Flutter: SharedPreferences

## 라이선스

이 프로젝트는 NUGGO의 소유입니다.

## 문의

- Email: support@nuggo.app
- 개발자: 조용상
