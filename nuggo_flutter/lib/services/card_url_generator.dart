import 'dart:convert';
import '../models/card_data.dart';

/// 카드 데이터 → GitHub Pages URL 생성
///
/// URL 형태: https://[유저명].github.io/nuggo-card/?d=<base64url>
///
/// 받는 사람이 URL 탭 → 브라우저에서 열림 → 앱 미리보기와 동일한 인터랙티브 카드
/// 전화/이메일/카카오 아이콘 탭 → 해당 앱 즉시 실행
class CardUrlGenerator {
  // nuggo 리포의 GitHub Pages (nuggo-card/ 폴더가 루트로 배포됨)
  static const String _baseUrl =
      'https://jaguar7307-hash.github.io/nuggo/';

  /// 카드 URL 생성 (단축 키로 URL 길이 최소화)
  ///
  /// 단축 키 목록 (index.html parseCardData와 동일):
  ///   n=fullName, j=jobTitle, c=companyName
  ///   p=phone,    s=sms,      e=email
  ///   w=website,  k=kakao,    a=address
  ///   sl=slogan,  t=theme,    pi=profileImage(URL만)
  ///   f=fontIndex(0-4), li=linkedin
  ///   pu=portfolioUrl,  sh=shareLink
  static String generate(CardData data) {
    final Map<String, dynamic> payload = {};

    // 비어있는 필드는 포함하지 않아 URL 최소화
    if (data.fullName.trim().isNotEmpty)    payload['n']  = data.fullName.trim();
    if (data.jobTitle.trim().isNotEmpty)    payload['j']  = data.jobTitle.trim();
    if (data.companyName.trim().isNotEmpty) payload['c']  = data.companyName.trim();
    if (data.phone.trim().isNotEmpty)       payload['p']  = data.phone.trim();
    if (data.sms.trim().isNotEmpty)         payload['s']  = data.sms.trim();
    if (data.email.trim().isNotEmpty)       payload['e']  = data.email.trim();
    if (data.website.trim().isNotEmpty)     payload['w']  = data.website.trim();
    if (data.kakao.trim().isNotEmpty)       payload['k']  = data.kakao.trim();
    if (data.address.trim().isNotEmpty)     payload['a']  = data.address.trim();
    if (data.slogan.trim().isNotEmpty)      payload['sl'] = data.slogan.trim();
    if (data.theme.trim().isNotEmpty)       payload['t']  = data.theme.trim();
    if (data.linkedin.trim().isNotEmpty)    payload['li'] = data.linkedin.trim();
    if (data.shareLink.trim().isNotEmpty)   payload['sh'] = data.shareLink.trim();

    // 포트폴리오 URL (파일 base64는 제외)
    final pu = (data.portfolioUrl ?? '').trim();
    if (pu.isNotEmpty) payload['pu'] = pu;

    // 프로필 이미지: 웹 URL만 포함 (로컬/base64는 외부에서 접근 불가)
    final img = data.profileImage ?? '';
    if (img.startsWith('http')) payload['pi'] = img;

    // 폰트 인덱스 (기본값 1=modernSans는 생략해 URL 단축)
    if (data.font.index != 1) payload['f'] = data.font.index;

    final json = jsonEncode(payload);
    final encoded = base64Url.encode(utf8.encode(json));
    // hash(#) 방식: 데이터가 서버로 전송되지 않아 프라이버시 보호
    return '${_baseUrl}#d=$encoded';
  }

  /// 이름만 포함한 짧은 설명 텍스트 (공유 메시지 본문용)
  static String shareText(CardData data) {
    final name = data.fullName.trim().isNotEmpty ? data.fullName.trim() : 'NUGGO';
    final url = generate(data);
    return '$name 님의 디지털 명함\n$url';
  }
}
