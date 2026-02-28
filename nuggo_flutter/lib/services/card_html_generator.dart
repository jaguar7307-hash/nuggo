import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/card_data.dart';

/// 명함 데이터로 자기완결형 HTML 카드를 생성한다.
/// - 받는 사람이 브라우저에서 열면 전화/이메일/카카오/웹사이트 링크 전부 작동
/// - 백엔드 없이 동작 (파일 하나로 완결)
class CardHtmlGenerator {
  /// 인터랙티브 HTML 문자열 반환 (WebView에서 바로 로드 가능)
  static String buildHtmlContent(CardData data) => _buildHtml(data);

  static Future<XFile> generate(CardData data) async {
    final html = _buildHtml(data);
    final dir = await getTemporaryDirectory();
    final safeName = data.fullName.trim().isEmpty
        ? 'nuggo_card'
        : data.fullName.trim().replaceAll(RegExp(r'[^\w가-힣]'), '_');
    final file = File('${dir.path}/${safeName}_card.html');
    await file.writeAsString(html, flush: true);
    return XFile(file.path, mimeType: 'text/html', name: '${safeName}_card.html');
  }

  static String _buildHtml(CardData data) {
    final bgColor = data.theme.startsWith('#') ? data.theme : '#1a1c2e';
    final isLight = _isLight(bgColor);
    final textColor = isLight ? '#111827' : '#FFFFFF';
    final subColor = isLight ? '#6B7280' : '#9CA3AF';
    final accentColor = isLight ? '#4F46E5' : '#A5B4FC';
    final iconBg = isLight ? 'rgba(0,0,0,0.07)' : 'rgba(255,255,255,0.12)';

    // 아이콘 SVG 인라인
    const phoneIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M6.6 10.8c1.4 2.8 3.8 5.1 6.6 6.6l2.2-2.2c.3-.3.7-.4 1-.2 1.1.4 2.3.6 3.6.6.6 0 1 .4 1 1V20c0 .6-.4 1-1 1-9.4 0-17-7.6-17-17 0-.6.4-1 1-1h3.5c.6 0 1 .4 1 1 0 1.3.2 2.5.6 3.6.1.3 0 .7-.2 1L6.6 10.8z"/></svg>';
    const msgIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/></svg>';
    const mailIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/></svg>';
    const webIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/></svg>';
    const kakaoIcon =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3C6.48 3 2 6.48 2 10.8c0 2.73 1.65 5.14 4.15 6.62-.17.62-.65 2.28-.75 2.64-.12.45.17.44.35.32.14-.09 2.24-1.54 3.14-2.17.69.1 1.39.15 2.11.15 5.52 0 10-3.48 10-7.77S17.52 3 12 3z"/></svg>';

    // 배경 스타일 (이미지 or 색상)
    final backgroundCss = data.theme.startsWith('http')
        ? 'background: url("${data.theme}") center/cover no-repeat;'
        : 'background: $bgColor;';

    // 프로필 이미지 (web URL만, 로컬 파일은 제외)
    final profileImgHtml = (data.profileImage ?? '').startsWith('http')
        ? '<img src="${data.profileImage}" alt="profile" style="width:72px;height:72px;border-radius:50%;object-fit:cover;border:3px solid rgba(255,255,255,0.3);margin-bottom:8px;">'
        : '';

    // 액션 버튼 빌더
    String btn(String href, String icon, String label, bool show) {
      if (!show) return '';
      return '''
        <a href="$href" class="action-btn">
          <span class="action-icon">$icon</span>
          <span class="action-label">$label</span>
        </a>''';
    }

    final phoneNum = data.phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final smsNum = data.sms.isNotEmpty ? data.sms.replaceAll(RegExp(r'[\s\-\(\)]'), '') : phoneNum;
    final kakaoHref = data.kakao.startsWith('http')
        ? data.kakao
        : (data.kakao.isNotEmpty ? 'https://open.kakao.com/me/${Uri.encodeComponent(data.kakao)}' : '');
    final websiteHref = data.website.isNotEmpty
        ? (data.website.startsWith('http') ? data.website : 'https://${data.website}')
        : '';

    final actions = [
      btn('tel:$phoneNum', phoneIcon, 'PHONE', data.phone.isNotEmpty),
      btn('sms:$smsNum', msgIcon, 'MESSAGE', smsNum.isNotEmpty),
      btn('mailto:${data.email}', mailIcon, 'EMAIL', data.email.isNotEmpty),
      btn(websiteHref, webIcon, 'WEBSITE', websiteHref.isNotEmpty),
      btn(kakaoHref, kakaoIcon, 'KAKAO', kakaoHref.isNotEmpty),
    ].where((s) => s.isNotEmpty).join('\n');

    return '''<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">
  <title>${_esc(data.fullName.isNotEmpty ? data.fullName : 'NUGGO')}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    body { min-height: 100dvh; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #0f172a; font-family: -apple-system, 'Noto Sans KR', sans-serif; padding: 24px 16px 32px; }

    .card {
      width: 100%; max-width: 340px;
      border-radius: 24px;
      $backgroundCss
      padding: 28px 24px 20px;
      border: 1px solid rgba(255,255,255,0.15);
      box-shadow: 0 25px 60px rgba(0,0,0,0.5);
      display: flex; flex-direction: column; gap: 0;
      overflow: hidden;
    }
    .overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.04); border-radius: 24px; pointer-events: none; }

    .top { text-align: center; padding-bottom: 16px; }
    .slogan { font-size: 10px; font-weight: 600; letter-spacing: 2px; color: $subColor; margin-bottom: 8px; }
    .divider { width: 24px; height: 1px; background: $subColor; opacity: 0.4; margin: 6px auto; }
    .name { font-size: 26px; font-weight: 800; color: $textColor; letter-spacing: -0.5px; margin-bottom: 3px; }
    .job-title { font-size: 10px; font-weight: 700; letter-spacing: 2.5px; color: $accentColor; text-transform: uppercase; }
    .company { font-size: 9px; letter-spacing: 1.5px; color: $subColor; text-transform: uppercase; margin-top: 2px; }

    .sep { height: 1px; background: rgba(255,255,255,0.1); margin: 12px 0; }

    .actions { display: flex; flex-wrap: wrap; justify-content: center; gap: 6px; padding: 4px 0; }
    .action-btn {
      display: flex; flex-direction: column; align-items: center; gap: 4px;
      text-decoration: none; color: $textColor;
      background: $iconBg;
      border-radius: 14px;
      padding: 10px 8px 8px;
      width: 60px;
      transition: transform 0.15s, opacity 0.15s;
    }
    .action-btn:active { transform: scale(0.93); opacity: 0.8; }
    .action-icon { width: 22px; height: 22px; color: $textColor; }
    .action-icon svg { width: 22px; height: 22px; fill: $textColor; }
    .action-label { font-size: 7.5px; font-weight: 700; letter-spacing: 0.5px; color: $subColor; text-transform: uppercase; }

    ${data.address.isNotEmpty ? '''
    .address {
      display: flex; align-items: center; justify-content: center; gap: 4px;
      margin-top: 10px; padding: 5px 10px;
      background: rgba(255,255,255,0.1); border-radius: 12px;
      font-size: 8px; font-weight: 700; letter-spacing: 1px; color: $subColor;
      text-transform: uppercase;
    }
    .address svg { width: 10px; height: 10px; flex-shrink: 0; }
    ''' : ''}

    .footer {
      width: 100%; max-width: 340px; margin-top: 20px;
      background: rgba(255,255,255,0.06);
      border-radius: 16px; padding: 14px 18px;
      display: flex; align-items: center; gap: 12px;
    }
    .footer-logo {
      width: 32px; height: 32px; background: #6366F1;
      border-radius: 9px; display: flex; align-items: center; justify-content: center;
      font-size: 18px; font-weight: 900; color: white; flex-shrink: 0;
    }
    .footer-text { flex: 1; }
    .footer-title { font-size: 12px; font-weight: 800; color: white; }
    .footer-sub { font-size: 10px; color: #9CA3AF; margin-top: 1px; }
    .footer-cta {
      background: #6366F1; color: white; border: none;
      border-radius: 10px; padding: 8px 14px;
      font-size: 11px; font-weight: 700; cursor: pointer;
      text-decoration: none; white-space: nowrap;
    }
    .footer-cta:active { opacity: 0.8; }
  </style>
</head>
<body>
  <div class="card">
    <div class="top">
      $profileImgHtml
      ${data.slogan.isNotEmpty ? '<p class="slogan">${_esc(data.slogan)}</p><div class="divider"></div>' : ''}
      <h1 class="name">${_esc(data.fullName)}</h1>
      ${data.jobTitle.isNotEmpty ? '<p class="job-title">${_esc(data.jobTitle)}</p>' : ''}
      ${data.companyName.isNotEmpty ? '<p class="company">${_esc(data.companyName)}</p>' : ''}
    </div>
    <div class="sep"></div>
    <div class="actions">
$actions
    </div>
    ${data.address.isNotEmpty ? '''
    <div class="address">
      <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>
      ${_esc(data.address)}
    </div>''' : ''}
  </div>

  <div class="footer">
    <div class="footer-logo">N</div>
    <div class="footer-text">
      <div class="footer-title">NUGGO</div>
      <div class="footer-sub">나도 명함 만들기</div>
    </div>
    <a href="https://nuggo.me" class="footer-cta">시작하기 →</a>
  </div>

  <script>
    // 전화/메일 링크가 없는 경우 빈 href 클릭 방지
    document.querySelectorAll('.action-btn').forEach(function(btn) {
      if (!btn.getAttribute('href') || btn.getAttribute('href') === '') {
        btn.style.display = 'none';
      }
    });
  </script>
</body>
</html>''';
  }

  static bool _isLight(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      final full = h.length == 3 ? h.split('').map((c) => '$c$c').join('') : h;
      final r = int.parse(full.substring(0, 2), radix: 16);
      final g = int.parse(full.substring(2, 4), radix: 16);
      final b = int.parse(full.substring(4, 6), radix: 16);
      return ((r * 299) + (g * 587) + (b * 114)) / 1000 >= 128;
    } catch (_) {
      return false;
    }
  }

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
