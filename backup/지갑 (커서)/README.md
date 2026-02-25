# 지갑 (커서) - 백업

지갑 페이지 재개발을 위한 보관용 백업입니다.

## 저장일
2025-02-25

## 포함 내용
- `wallet_screen.dart` - 지갑 화면 전체 소스 (디지털/스캔 명함 관리, 스캔 기능 UI 포함)

## 복원 방법
1. `wallet_screen.dart`를 `nuggo_flutter/lib/screens/wallet_screen.dart`로 복사
2. import 경로는 `lib/screens/` 기준으로 작성되어 있음 (`../constants/theme.dart`, `../providers/app_provider.dart`)

## 주요 기능
- 디지털 명함 / 스캔 명함 통계 및 필터
- 명함 스캔 CTA (카메라, 갤러리, NFC)
- 검색, 정렬 (최신순/이름순/회사순)
- 연락처 카드 타일 (전화, 이메일 빠른 액션)
