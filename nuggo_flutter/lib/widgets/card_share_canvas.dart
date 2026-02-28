import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/card_data.dart';
import '../services/card_url_generator.dart';
import 'business_card.dart';

/// 공유용 PNG 이미지 캔버스 (CardCaptureService에서 오프스크린 렌더링)
/// 레이아웃: [상단 여백] + [세로형 명함] + [QR + 버튼 푸터] + [하단 여백]
class CardShareCanvas extends StatelessWidget {
  final CardData data;

  // 세로형 카드 비율: kBusinessCardAspectRatio ≈ 0.625 (width/height)
  static const double canvasWidth = 400.0;
  static const double cardWidth = 320.0;
  static const double cardHeight = cardWidth / kBusinessCardAspectRatio; // ≈ 512
  static const double footerHeight = 128.0;
  static const double canvasHeight = 24 + cardHeight + 16 + footerHeight + 24;

  const CardShareCanvas({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isLight = _isLightTheme(data.theme);
    final bgColor =
        isLight ? const Color(0xFFF0F0F5) : const Color(0xFF0D1117);
    final cardBg = isLight ? Colors.white : const Color(0xFF1E2530);
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.10);

    final webUrl = CardUrlGenerator.generate(data);

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: ColoredBox(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // ── 명함 카드 (세로형) ──────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: OverflowBox(
                  maxWidth: cardWidth,
                  maxHeight: cardHeight,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: cardWidth,
                    height: cardHeight,
                    child: BusinessCard(
                      data: data,
                      forceActionIconsEnabled: true,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── 푸터: QR + 버튼 2개 ──────────────────────────────────
            SizedBox(
              width: canvasWidth - 32,
              height: footerHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 좌: QR 코드 ────────────────────────────────────
                  Container(
                    width: 114,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        QrImageView(
                          data: webUrl,
                          version: QrVersions.auto,
                          size: 84,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.black,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '웹 명함 열기',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 8,
                            color: const Color(0xFF6366F1),
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ── 우: 버튼 2개 (세로 배열) ───────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ① 명함 열기 (QR 안내)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Text('🪪',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '명함 열기',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        'QR 스캔 → 전화·이메일 연결',
                                        style: GoogleFonts.manrope(
                                          fontSize: 9,
                                          color: subColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ② 나도 명함 만들기 (앱 다운로드)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1)
                                  .withValues(alpha: isLight ? 0.10 : 0.20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF6366F1)
                                    .withValues(alpha: 0.30),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Text('📲',
                                    style: TextStyle(fontSize: 22)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '나도 명함 만들기',
                                        style: GoogleFonts.notoSansKr(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6366F1),
                                        ),
                                        maxLines: 1,
                                      ),
                                      Text(
                                        'NUGGO 앱 무료 다운로드',
                                        style: GoogleFonts.manrope(
                                          fontSize: 9,
                                          color: const Color(0xFF818CF8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  bool _isLightTheme(String theme) {
    if (!theme.startsWith('#')) return false;
    final hex = theme.replaceAll('#', '');
    final full =
        hex.length == 3 ? hex.split('').map((c) => '$c$c').join('') : hex;
    final r = int.tryParse(full.substring(0, 2), radix: 16) ?? 0;
    final g = int.tryParse(full.substring(2, 4), radix: 16) ?? 0;
    final b = int.tryParse(full.substring(4, 6), radix: 16) ?? 0;
    return ((r * 299) + (g * 587) + (b * 114)) / 1000 >= 128;
  }
}
