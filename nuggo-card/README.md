# nuggo-card

nuggo 앱에서 공유하는 **인터랙티브 디지털 명함 웹페이지**

카카오톡/문자로 링크를 보내면 → 앱 미리보기와 동일하게 생긴 HTML 명함이 열리고  
전화·문자·이메일·카카오 아이콘이 실제로 동작합니다.

---

## 동작 방식

```
nuggo 앱 → 공유 버튼
    ↓
CardUrlGenerator.generate(cardData)
    ↓
https://[유저명].github.io/nuggo-card/#d=BASE64_DATA
    ↓ 상대방이 탭
index.html → URL 해시 파싱 → 명함 렌더링 → 아이콘 동작
```

---

## GitHub Pages 배포 순서

1. GitHub에서 **`nuggo-card`** 레포지토리 생성 (Public)
2. 이 폴더의 파일 업로드:
   - `index.html`
   - `card.png` (앱 명함 스크린샷 - TODO 교체 필요)
3. **Settings → Pages → Branch: main → Save**
4. 배포 URL 확인: `https://[유저명].github.io/nuggo-card/`

---

## 배포 후 필수 업데이트

### 1. `index.html` 안의 TODO 3곳
```html
<!-- TODO: og:image -->
<meta property="og:image" content="https://[TODO].github.io/nuggo-card/card.png">
<!-- TODO: og:url -->
<meta property="og:url"   content="https://[TODO].github.io/nuggo-card/">
```

### 2. Flutter `CardUrlGenerator._baseUrl`
```dart
// lib/services/card_url_generator.dart
static const String _baseUrl = 'https://[유저명].github.io/nuggo-card/';
```

### 3. `card.png` 교체
- 앱의 명함 미리보기 스크린샷을 `card.png`로 저장
- 카카오톡 링크 공유 시 이 이미지가 썸네일로 표시됨

---

## 카카오톡 OG 캐시 초기화 (배포 후 필수)

배포 완료 후 아래 URL에서 링크를 입력하면 미리보기 이미지가 정상 표시됩니다:

👉 https://developers.kakao.com/tool/clear/og

---

## 데이터 파라미터 형식

Flutter `CardUrlGenerator`가 생성하는 base64url 인코딩 JSON:

| 키  | 필드        | 비고 |
|-----|-------------|------|
| `n` | fullName    | |
| `j` | jobTitle    | |
| `c` | companyName | |
| `p` | phone       | |
| `s` | sms         | |
| `e` | email       | |
| `w` | website     | |
| `k` | kakao       | |
| `a` | address     | |
| `sl`| slogan      | |
| `t` | theme       | hex 색상 또는 이미지 URL |
| `pi`| profileImage| http URL만 (base64 제외) |
| `f` | font        | 0-4 (기본값 1 생략) |
| `li`| linkedin    | |
| `pu`| portfolioUrl| |
| `sh`| shareLink   | |

---

## 로컬 테스트

```
# 브라우저에서 직접 열기
index.html?d=BASE64_DATA

# 테스트 URL 예시 (홍길동, 전화 010-1234-5678)
index.html#d=eyJuIjoi7ZmN6ri464+ZIiwicCI6IjAxMC0xMjM0LTU2NzgiLCJlIjoiaGVsbG9AbnVnZ28ubWUiLCJ0IjoiIzFhMWMyZSJ9
```
