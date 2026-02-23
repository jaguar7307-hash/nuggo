import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_data.dart';
import 'business_card.dart';

String _normalizePhone(String raw) {
  return raw
      .replaceAll(RegExp(r'[\s\-\(\)\.]'), '')
      .replaceAll(RegExp(r'[^\d+]'), '');
}

/// BusinessCard를 래핑하여 액션(전화, 메일, 공유 등) 로직을 제공하는 인터랙티브 명함.
class DigitalCard extends StatelessWidget {
  final CardData data;
  final bool isLarge;
  final VoidCallback? onAddressClick;

  const DigitalCard({
    super.key,
    required this.data,
    this.isLarge = true,
    this.onAddressClick,
  });

  Future<void> _handleAction(
    BuildContext context,
    String type,
    String value,
  ) async {
    if (value.isEmpty && type != 'share') return;

    if (type == 'share') {
      String shareUrl =
          data.shareLink.trim().isEmpty ? 'https://nuggo.me' : data.shareLink;
      if (!shareUrl.startsWith('http')) shareUrl = 'https://$shareUrl';
      await SharePlus.instance.share(
        ShareParams(
          text: shareUrl,
          subject:
              '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}',
        ),
      );
      return;
    }

    final Uri? uri;
    switch (type) {
      case 'call':
        final tel = _normalizePhone(value);
        uri = tel.isNotEmpty ? Uri(scheme: 'tel', path: tel) : null;
        break;
      case 'sms':
        final sms = _normalizePhone(value);
        uri = sms.isNotEmpty ? Uri(scheme: 'sms', path: sms) : null;
        break;
      case 'mail':
        uri = Uri(scheme: 'mailto', path: value);
        break;
      case 'mail_naver':
        uri = Uri.parse(
          'https://mail.naver.com/write?to=${Uri.encodeComponent(value)}',
        );
        break;
      case 'website':
      case 'portfolio':
        final url = value.startsWith('http') ? value : 'https://$value';
        uri = value.trim().isEmpty ? null : Uri.parse(url);
        break;
      case 'kakao':
        if (value.startsWith('http') || value.contains('open.kakao.com')) {
          uri = Uri.parse(
            value.startsWith('http') ? value : 'https://$value',
          );
        } else if (value.trim().isNotEmpty) {
          uri = Uri.parse(
            'https://open.kakao.com/me/${Uri.encodeComponent(value.trim())}',
          );
        } else {
          uri = null;
        }
        break;
      default:
        uri = null;
    }

    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('링크를 열 수 없습니다.')),
          );
        }
      }
    }
  }

  void _showMailChoice(BuildContext context, CardData data) {
    if (data.email.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Material(
          color: Theme.of(ctx).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '메일 보내기',
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleAction(ctx, 'mail', data.email);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                size: 40,
                                color: Theme.of(ctx).colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '기본 메일 앱',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _handleAction(ctx, 'mail_naver', data.email);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/naver_mail_icon.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '네이버 메일',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePortfolioAction(BuildContext context, CardData data) async {
    final url = (data.portfolioUrl ?? '').trim();
    final fileData = data.portfolioFile;
    if (url.isNotEmpty) {
      await _handleAction(
        context,
        'portfolio',
        url.startsWith('http') ? url : 'https://$url',
      );
    } else if (fileData != null &&
        fileData.isNotEmpty &&
        fileData.startsWith('data:')) {
      try {
        final parts = fileData.split(',');
        if (parts.length >= 2) {
          final bytes = base64Decode(parts.last);
          final mimeMatch = RegExp(r'data:([^;]+);').firstMatch(fileData);
          final mime = mimeMatch?.group(1) ?? 'application/octet-stream';
          final ext = mime.contains('pdf')
              ? 'pdf'
              : (mime.contains('image') ? 'jpg' : 'bin');
          await SharePlus.instance.share(ShareParams(
            files: [
              XFile.fromData(bytes, mimeType: mime, name: 'portfolio.$ext'),
            ],
          ));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return BusinessCard(
      data: data,
      onAddressClick: onAddressClick,
      onAction: (type, value) {
        if (type == 'mail') {
          _showMailChoice(context, data);
        } else if (type == 'portfolio') {
          _handlePortfolioAction(context, data);
        } else {
          _handleAction(context, type, value);
        }
      },
    );
  }
}
