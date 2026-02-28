import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/card_data.dart';
import '../services/card_html_generator.dart';

/// 인터랙티브 디지털 명함 WebView
/// - 동일한 HTML을 앱 내에서 렌더링
/// - tel: / sms: / mailto: / https: 탭 시 NavigationDelegate가 OS 기본 앱으로 연결
/// - 공유 시에도 이 HTML 파일이 전달됨 → 받는 사람도 동일한 경험
class BusinessCardWebView extends StatefulWidget {
  final CardData data;

  const BusinessCardWebView({super.key, required this.data});

  /// 전체화면 슬라이드업 모달
  static Future<void> show(BuildContext context, CardData data) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, _, __) =>
            BusinessCardWebView(data: data),
        transitionsBuilder: (ctx, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  @override
  State<BusinessCardWebView> createState() => _BusinessCardWebViewState();
}

class _BusinessCardWebViewState extends State<BusinessCardWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final html = CardHtmlGenerator.buildHtmlContent(widget.data);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),

          /// 핵심: tel: / sms: / mailto: / https: 를 OS 기본 앱으로 연결
          onNavigationRequest: (request) async {
            final url = request.url;

            // 초기 HTML 로딩은 허용
            if (url == 'about:blank' || url.startsWith('data:')) {
              return NavigationDecision.navigate;
            }

            final uri = Uri.tryParse(url);
            if (uri == null) return NavigationDecision.prevent;

            final scheme = uri.scheme.toLowerCase();
            if (['tel', 'sms', 'mailto', 'https', 'http', 'kakaotalk']
                .contains(scheme)) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('해당 앱을 실행할 수 없습니다.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {}
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(html, baseUrl: 'https://nuggo.me');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Container(
              color: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    '디지털 명함 미리보기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.touch_app_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '탭하면 바로 연결',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
            ),
            // WebView
            Expanded(
              child: Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
