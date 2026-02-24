import 'package:flutter/material.dart';
import '../models/card_data.dart';
import 'digital_card.dart';

/// 명함을 지정 크기로 표시. 내 명함·에디터·미리보기 공통.
/// width, height만 바꿔서 동일 레이아웃 유지. AspectRatio로 비율 고정해 플랫폼별 일관성 확보.
class CardDisplay extends StatelessWidget {
  static const double canonicalWidth = 242.55;
  static const double canonicalHeight = 388.08;

  final double width;
  final double height;
  final CardData data;
  final VoidCallback? onAddressClick;
  final bool showShadow;

  const CardDisplay({
    super.key,
    required this.width,
    required this.height,
    required this.data,
    this.onAddressClick,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = SizedBox(
      width: canonicalWidth,
      height: canonicalHeight,
      child: DigitalCard(
        data: data,
        isLarge: false,
        onAddressClick: onAddressClick,
      ),
    );

    final content = FittedBox(
      fit: BoxFit.contain,
      alignment: Alignment.center,
      child: card,
    );

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: content,
    );

    if (!showShadow) {
      return SizedBox(width: width, height: height, child: clipped);
    }

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 50,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: clipped,
      ),
    );
  }
}
