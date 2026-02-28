import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card_data.dart';
import '../widgets/card_share_canvas.dart';

/// CardShareCanvas(카드+푸터)를 오프스크린에서 렌더링해 PNG XFile로 반환.
class CardCaptureService {
  static const double _pixelRatio = 3.0;

  /// 명함 이미지(카드+나도명함만들기/친구추가 푸터) 캡처 후 XFile 반환.
  /// 반드시 valid BuildContext (Overlay 접근 가능) 를 전달해야 한다.
  static Future<XFile?> captureCard(
    BuildContext context,
    CardData data,
  ) async {
    if (!context.mounted) return null;

    final repaintKey = GlobalKey();
    Completer<Uint8List?> completer = Completer();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -(CardShareCanvas.canvasWidth * _pixelRatio * 2),
        top: 0,
        width: CardShareCanvas.canvasWidth,
        height: CardShareCanvas.canvasHeight,
        child: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 1.0),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: repaintKey,
              child: CardShareCanvas(data: data),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    overlay.insert(entry);

    try {
      // 프레임 2회 대기 (레이아웃 + 페인트 완료)
      await Future.delayed(const Duration(milliseconds: 300));

      final renderObj = repaintKey.currentContext?.findRenderObject();
      if (renderObj == null || renderObj is! RenderRepaintBoundary) {
        entry.remove();
        return null;
      }

      final image = await renderObj.toImage(pixelRatio: _pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      completer.complete(byteData?.buffer.asUint8List());
    } catch (_) {
      if (!completer.isCompleted) completer.complete(null);
    } finally {
      entry.remove();
    }

    final bytes = await completer.future;
    if (bytes == null) return null;

    final dir = await getTemporaryDirectory();
    final safeName = data.fullName.trim().isEmpty
        ? 'card'
        : data.fullName.trim().replaceAll(RegExp(r'[^\w가-힣]'), '_');
    final file = File('${dir.path}/${safeName}_nuggo.png');
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: 'image/png');
  }
}
