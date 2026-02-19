import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/theme.dart';

/// NUGGO 로고 (SVG 동일: 원 + 눈 2개 + 미소 곡선)
/// 색상 #1A4794, viewBox 0 0 100 100
class NuggoLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const NuggoLogo({super.key, this.size = 40, this.color});

  static const Color defaultColor = Color(0xFF1A4794);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NuggoLogoPainter(color: color ?? defaultColor),
        size: Size(size, size),
      ),
    );
  }
}

class _NuggoLogoPainter extends CustomPainter {
  final Color color;

  _NuggoLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 바깥 원 (r=45, stroke 5)
    canvas.drawCircle(const Offset(50, 50), 45, strokePaint);

    // 눈 (35,40) r=5, (65,40) r=5
    canvas.drawCircle(const Offset(35, 40), 5, fillPaint);
    canvas.drawCircle(const Offset(65, 40), 5, fillPaint);

    // 미소 경로 M30 65 C 40 75, 60 75, 70 65
    final path = Path()
      ..moveTo(30, 65)
      ..cubicTo(40, 75, 60, 75, 70, 65);
    canvas.drawPath(path, strokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NuggoLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// NUGGO 텍스트 로고 (Inter, NUG 200 #0055FF / GO 700 #FF4F00, letterSpacing -0.04em)
/// variant: brand = 브랜드 컬러, white = 어두운 배경용 (흰색 계열)
class NuggoTextLogo extends StatelessWidget {
  final double fontSize;
  final LogoVariant variant;

  const NuggoTextLogo({
    super.key,
    this.fontSize = 24,
    this.variant = LogoVariant.brand,
  });

  static const double _letterSpacingEm = -0.04;

  @override
  Widget build(BuildContext context) {
    final nugColor = variant == LogoVariant.brand
        ? AppTheme.logoPrimary
        : Colors.white;
    final goColor = variant == LogoVariant.brand
        ? AppTheme.logoTangerine
        : Colors.white.withValues(alpha: 0.8);
    final letterSpacing = fontSize * _letterSpacingEm;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'NUG',
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w200,
            letterSpacing: letterSpacing,
            color: nugColor,
          ),
        ),
        Text(
          'GO',
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: letterSpacing,
            color: goColor,
          ),
        ),
      ],
    );
  }
}

enum LogoVariant { brand, white }
