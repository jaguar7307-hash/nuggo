import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card_data.dart';
import '../widgets/business_card.dart';

/// BusinessCard 위젯을 오프스크린에서 렌더링해 PNG XFile로 반환.
/// 화면에 표시 중인 카드 위젯과 무관하게 항상 고화질 캡처 가능.
class CardCaptureService {
  static const double _cardW = kBusinessCardAspectWidth;
  static const double _cardH = kBusinessCardAspectHeight;
  static const double _pixelRatio = 3.0;

  /// [context]: BuildContext (Overlay 접근용)
  /// [data]: 명함 데이터
  /// 성공 시 PNG XFile 반환, 실패 시 null
  static Future<XFile?> captureCard(
    BuildContext context,
    CardData data,
  ) async {
    final repaintKey = GlobalKey();
    final completer = Completer<Uint8List?>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        // 화면 밖에 렌더링 (시각적으로 보이지 않음)
        left: -(_cardW * _pixelRatio * 2),
        top: 0,
        width: _cardW,
        height: _cardH,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: repaintKey,
              child: BusinessCard(data: data),
            ),
          ),
        ),
      ),
    );

    // Overlay에 삽입 후 렌더링 대기
    if (!context.mounted) return null;
    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);

    try {
      // 프레임 2번 대기 (레이아웃+페인트 완료 보장)
      await Future.delayed(const Duration(milliseconds: 250));

      final renderObj = repaintKey.currentContext?.findRenderObject();
      if (renderObj == null || renderObj is! RenderRepaintBoundary) {
        entry.remove();
        return null;
      }

      final image = await renderObj.toImage(pixelRatio: _pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        entry.remove();
        return null;
      }

      completer.complete(byteData.buffer.asUint8List());
    } catch (e) {
      if (!completer.isCompleted) completer.complete(null);
    } finally {
      entry.remove();
    }

    final bytes = await completer.future;
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final safeName = (data.fullName.trim().replaceAll(RegExp(r'[^\w]'), '_'))
        .isNotEmpty
        ? data.fullName.trim().replaceAll(RegExp(r'[^\w]'), '_')
        : 'card';
    final file = File('${dir.path}/${safeName}_nuggo.png');
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: 'image/png');
  }
}
