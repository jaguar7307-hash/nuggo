import 'dart:convert';
import '../models/card_data.dart';

/// 카드 데이터 → GitHub Pages URL 생성
/// 
/// URL 형태: https://jaguar7307-hash.github.io/nuggo/card.html?d=<base64>
/// 
/// 받는 사람이 URL 탭 → 브라우저에서 열림 → 앱 미리보기와 동일한 인터랙티브 카드
/// 전화/이메일/카카오 아이콘 탭 → 해당 앱 즉시 실행
class CardUrlGenerator {
  static const String _baseUrl =
      'https://jaguar7307-hash.github.io/nuggo/card.html';

  /// 카드 URL 생성 (공유용 짧은 키 사용)
  static String generate(CardData data) {
    final Map<String, dynamic> payload = {};

    // 비어있는 필드는 포함하지 않아 URL을 짧게 유지
    if (data.fullName.trim().isNotEmpty) payload['n'] = data.fullName.trim();
    if (data.jobTitle.trim().isNotEmpty) payload['j'] = data.jobTitle.trim();
    if (data.companyName.trim().isNotEmpty) payload['c'] = data.companyName.trim();
    if (data.phone.trim().isNotEmpty) payload['p'] = data.phone.trim();
    if (data.sms.trim().isNotEmpty) payload['s'] = data.sms.trim();
    if (data.email.trim().isNotEmpty) payload['e'] = data.email.trim();
    if (data.website.trim().isNotEmpty) payload['w'] = data.website.trim();
    if (data.kakao.trim().isNotEmpty) payload['k'] = data.kakao.trim();
    if (data.address.trim().isNotEmpty) payload['a'] = data.address.trim();
    if (data.slogan.trim().isNotEmpty) payload['sl'] = data.slogan.trim();
    if (data.theme.trim().isNotEmpty) payload['t'] = data.theme.trim();

    // 프로필 이미지: URL 형태만 포함 (로컬 파일 경로는 외부에서 접근 불가)
    final img = data.profileImage ?? '';
    if (img.startsWith('http')) payload['pi'] = img;

    final json = jsonEncode(payload);
    final encoded = base64Url.encode(utf8.encode(json));
    return '$_baseUrl?d=$encoded';
  }

  /// 이름만 포함한 짧은 설명 텍스트 (공유 메시지 본문용)
  static String shareText(CardData data) {
    final name = data.fullName.trim().isNotEmpty ? data.fullName.trim() : 'NUGGO';
    final url = generate(data);
    return '$name 님의 디지털 명함\n$url';
  }
}
