import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/card_data.dart';
import 'business_card.dart';

/// 공유용 PNG 이미지 캔버스 (CardCaptureService에서 오프스크린 렌더링)
/// 레이아웃: [상단 여백] + [명함 카드] + [하단 버튼 2개] + [하단 여백]
class CardShareCanvas extends StatelessWidget {
  final CardData data;

  // 카드 비율: kBusinessCardAspectRatio = 242.55/388.08 ≈ 0.625 (세로형)
  static const double canvasWidth = 400.0;
  static const double cardWidth = 340.0;
  // 세로형: height = width / (width/height 비율) = width * 1.6
  static const double cardHeight = cardWidth / kBusinessCardAspectRatio; // ≈ 544
  static const double footerHeight = 76.0;
  static const double canvasHeight = 28 + cardHeight + 14 + footerHeight + 20;

  const CardShareCanvas({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool isLight = _isLightTheme(data.theme);
    final bgColor =
        isLight ? const Color(0xFFF0F0F5) : const Color(0xFF0D1117);

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: ColoredBox(
        color: bgColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 28),

            // ── 명함 카드 ──────────────────────────────────────
            // ClipRect + SizedBox로 BusinessCard를 정확한 크기로 잘라냄
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

            const SizedBox(height: 14),

            // ── 하단 버튼 2개 ──────────────────────────────────
            SizedBox(
              width: canvasWidth - 32,
              height: footerHeight,
              child: Row(
                children: [
                  // 왼쪽: 명함 열기
                  Expanded(
                    child: _FooterButton(
                      icon: Icons.credit_card_rounded,
                      label: '명함 열기',
                      sublabel: '아이콘 탭으로 연결',
                      iconColor: const Color(0xFF6366F1),
                      isLight: isLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 오른쪽: 나도 명함 만들기
                  Expanded(
                    child: _FooterButton(
                      icon: Icons.add_card_rounded,
                      label: '나도 명함 만들기',
                      sublabel: 'NUGGO 앱 다운로드',
                      iconColor: const Color(0xFF10B981),
                      isLight: isLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
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

class _FooterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color iconColor;
  final bool isLight;

  const _FooterButton({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.iconColor,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isLight ? Colors.white : const Color(0xFF1E2530);
    final textColor =
        isLight ? const Color(0xFF111827) : Colors.white;
    final subColor =
        isLight ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLight
              ? Colors.black.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSansKr(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  style: GoogleFonts.manrope(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
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
    );
  }
}
