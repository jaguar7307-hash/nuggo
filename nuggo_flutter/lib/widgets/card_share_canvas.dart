import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/card_data.dart';
import 'business_card.dart';

/// 공유용 이미지: 명함 카드 + 하단 푸터(나도 명함 만들기 / 친구 추가)
/// CardCaptureService에서 이 위젯을 오프스크린 렌더링해 PNG로 캡처한다.
class CardShareCanvas extends StatelessWidget {
  final CardData data;

  static const double canvasWidth = 360;
  static const double cardWidth = 280;
  static const double cardHeight = cardWidth / (242.55 / 388.08);
  static const double footerHeight = 88;
  static const double canvasHeight =
      24 + cardHeight + 16 + footerHeight + 16; // top-pad + card + gap + footer + bottom-pad

  const CardShareCanvas({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isLight = _isLightTheme(data.theme);
    final bgColor = isLight
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF111827);
    final textColor = isLight ? const Color(0xFF111827) : Colors.white;
    final subColor = isLight
        ? const Color(0xFF6B7280)
        : const Color(0xFF9CA3AF);

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: ColoredBox(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),
            // 명함 카드 (ClipRRect로 오버플로우 방지)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: ClipRect(
                  child: BusinessCard(data: data),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 푸터
            Container(
              width: canvasWidth - 32,
              height: footerHeight,
              decoration: BoxDecoration(
                color: isLight ? Colors.white : const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽: 나도 명함 만들기
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'N',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NUGGO',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '나도 명함 만들기 →',
                          style: GoogleFonts.notoSansKr(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        Text(
                          'nuggo.me',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: subColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 구분선
                  Container(
                    width: 1,
                    height: 48,
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  // 오른쪽: 친구 추가
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_add_rounded,
                          color: Color(0xFF6366F1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '친구 추가',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
