import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_data.dart';
import '../constants/theme.dart';

String _normalizePhone(String raw) {
  return raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '').replaceAll(RegExp(r'[^\d+]'), '');
}

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

  bool get _isHexTheme => data.theme.startsWith('#');

  bool get _isLightBackground {
    if (!_isHexTheme) return false;

    final hex = data.theme.replaceAll('#', '');
    final fullHex = hex.length == 3
        ? hex.split('').map((c) => '$c$c').join('')
        : hex;

    final r = int.tryParse(fullHex.substring(0, 2), radix: 16) ?? 0;
    final g = int.tryParse(fullHex.substring(2, 4), radix: 16) ?? 0;
    final b = int.tryParse(fullHex.substring(4, 6), radix: 16) ?? 0;

    final yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
    return yiq >= 128;
  }

  Future<void> _handleAction(
    BuildContext context,
    String type,
    String value,
  ) async {
    if (value.isEmpty && type != 'share') return;

    if (type == 'share') {
      String shareUrl = data.shareLink.trim().isEmpty
          ? 'https://nuggo.me'
          : data.shareLink;
      if (!shareUrl.startsWith('http')) shareUrl = 'https://$shareUrl';
      await SharePlus.instance.share(
        ShareParams(
          text: shareUrl,
          subject: '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}',
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
        final url = value.startsWith('http') ? value : 'https://$value';
        uri = Uri.parse(url);
        break;
      case 'portfolio':
        final url = value.startsWith('http') ? value : 'https://$value';
        uri = Uri.parse(url);
        break;
      case 'kakao':
        if (value.startsWith('http') || value.contains('open.kakao.com')) {
          uri = Uri.parse(value.startsWith('http') ? value : 'https://$value');
        } else if (value.trim().isNotEmpty) {
          uri = Uri.parse('https://open.kakao.com/me/${Uri.encodeComponent(value.trim())}');
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
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.mail_outline, size: 40, color: Theme.of(ctx).colorScheme.primary),
                            const SizedBox(height: 8),
                            const Text('기본 메일 앱', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Image.asset('assets/images/naver_mail_icon.png', width: 40, height: 40, fit: BoxFit.contain),
                            const SizedBox(height: 8),
                            const Text('네이버 메일', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      await _handleAction(context, 'portfolio', url.startsWith('http') ? url : 'https://$url');
    } else if (fileData != null && fileData.isNotEmpty && fileData.startsWith('data:')) {
      try {
        final parts = fileData.split(',');
        if (parts.length >= 2) {
          final bytes = base64Decode(parts.last);
          final mimeMatch = RegExp(r'data:([^;]+);').firstMatch(fileData);
          final mime = mimeMatch?.group(1) ?? 'application/octet-stream';
          final ext = mime.contains('pdf') ? 'pdf' : (mime.contains('image') ? 'jpg' : 'bin');
          await SharePlus.instance.share(ShareParams(
            files: [XFile.fromData(bytes, mimeType: mime, name: 'portfolio.$ext')],
          ));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isLightBackground ? Colors.black87 : Colors.white;
    final accentColor = _isLightBackground
        ? AppTheme.primary
        : Colors.white.withValues(alpha: 0.8);
    final hasProfileImage = data.profileImage != null;

    return AspectRatio(
      aspectRatio: 1 / 1.6,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: _isHexTheme
              ? _parseHexColor(data.theme)
              : const Color(0xFF1a1c1e),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          image: !_isHexTheme
              ? DecorationImage(
                  image: NetworkImage(data.theme),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Overlay
            if (!_isHexTheme)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),

            // Content (compact when !isLarge to avoid overflow)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(isLarge ? 32.0 : 8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxH = constraints.maxHeight;
                    final maxW = constraints.maxWidth;
                    final pad = isLarge ? 32.0 : 8.0;
                    final profH = hasProfileImage ? (isLarge ? 96.0 : 48.0) : (isLarge ? 80.0 : 30.0);
                    final gridRowH = (maxW - pad * 2 - (isLarge ? 8.0 : 4.0) * 2) / 3 / (isLarge ? 0.8 : 1.1);
                    final estBottom = gridRowH * 2 + (isLarge ? 6.0 : 2.0) + (isLarge ? 42.0 : 34.0) + (data.address.isNotEmpty ? (isLarge ? 24.0 : 14.0) : 0.0);
                    final estTotal = (profH + 100 + estBottom).clamp(250.0, 700.0);
                    final useScale = estTotal > maxH && maxH > 0 && maxW > 0;
                    final column = Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                  // Profile Image or Slogan
                  if (hasProfileImage)
                    Container(
                      width: isLarge ? 96 : 48,
                      height: isLarge ? 96 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                        image: DecorationImage(
                          image: data.profileImage!.startsWith('http')
                              ? NetworkImage(data.profileImage!)
                              : MemoryImage(
                                      Uri.parse(
                                        data.profileImage!,
                                      ).data!.contentAsBytes(),
                                    )
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: isLarge ? 32 : 6),
                        SizedBox(height: isLarge ? 24 : 6),
                        Text(
                          '"${data.slogan}"',
                          style: TextStyle(
                            fontSize: isLarge ? 20 : 11,
                            color: textColor,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                  // Identity
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        data.fullName,
                        style: TextStyle(
                          fontSize: isLarge ? 28 : 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isLarge ? 8 : 2),
                      Text(
                        data.jobTitle.toUpperCase(),
                        style: TextStyle(
                          fontSize: isLarge ? 10 : 8,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: accentColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isLarge ? 4 : 1),
                      Text(
                        data.companyName.toUpperCase(),
                        style: TextStyle(
                          fontSize: isLarge ? 9 : 7,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),

                  // Bottom Section: 3x2 액션 + 포트폴리오 (compact when !isLarge)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: isLarge ? 8 : 1,
                          crossAxisSpacing: isLarge ? 8 : 4,
                          childAspectRatio: isLarge ? 0.8 : 1.1,
                        ),
                        children: [
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(
                              icon: Icons.phone,
                              label: 'PHONE',
                              isEnabled: data.phone.isNotEmpty,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () =>
                                  _handleAction(context, 'call', data.phone),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(
                              icon: Icons.chat_bubble,
                              label: 'MESSAGE',
                              isEnabled: data.sms.isNotEmpty,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () => _handleAction(
                                  context,
                                  'sms',
                                  data.sms.isNotEmpty ? data.sms : data.phone,
                                ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(
                              icon: Icons.mail,
                              label: 'EMAIL',
                              isEnabled: data.email.isNotEmpty,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () => _showMailChoice(context, data),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(
                              icon: Icons.language,
                              label: 'WEBSITE',
                              isEnabled: data.website.isNotEmpty,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () => _handleAction(
                                context,
                                'website',
                                data.website,
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(
                              icon: Icons.chat_outlined,
                              label: 'KAKAO',
                              isEnabled: data.kakao.isNotEmpty,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () =>
                                  _handleAction(context, 'kakao', data.kakao),
                            ),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(
                              icon: Icons.share,
                              label: 'SNS',
                              isEnabled: true,
                              isLight: _isLightBackground,
                              isLarge: isLarge,
                              onTap: () => _handleAction(context, 'share', ''),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isLarge ? 6 : 2),
                      _CardActionItem(
                        icon: Icons.folder_open,
                        label: '포트폴리오',
                        isEnabled: ((data.portfolioUrl ?? '').isNotEmpty || (data.portfolioFile ?? '').isNotEmpty),
                        isLight: _isLightBackground,
                        isLarge: isLarge,
                        onTap: () => _handlePortfolioAction(context, data),
                      ),

                      // Address Pill
                      if (data.address.isNotEmpty) ...[
                        SizedBox(height: isLarge ? 12 : 4),
                        GestureDetector(
                          onTap: onAddressClick,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLarge ? 12 : 6,
                              vertical: isLarge ? 6 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: _isLightBackground
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: isLarge ? 10 : 6,
                                  color: textColor.withValues(alpha: 0.9),
                                ),
                                SizedBox(width: isLarge ? 6 : 3),
                                Flexible(
                                  child: Text(
                                    data.address.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: isLarge ? 8 : 6,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: textColor.withValues(alpha: 0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                      );
                    return SizedBox(
                      height: maxH,
                      width: maxW,
                      child: ClipRect(
                        child: useScale
                            ? FittedBox(
                                fit: BoxFit.fitHeight,
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: maxW,
                                  height: estTotal,
                                  child: column,
                                ),
                              )
                            : SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                clipBehavior: Clip.hardEdge,
                                child: column,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseHexColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}

class _CardActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final bool isLight;
  final bool isLarge;
  final VoidCallback onTap;

  const _CardActionItem({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.isLight,
    this.isLarge = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final circleSize = isLarge ? 38.0 : 22.0;
    final iconSize = isLarge ? 17.0 : 10.0;
    final textSize = isLarge ? 7.0 : 4.5;
    final touchSize = isLarge ? 56.0 : 34.0;
    final iconColor = isLight
        ? Colors.black87.withValues(alpha: isEnabled ? 1 : 0.3)
        : Colors.white.withValues(alpha: isEnabled ? 1 : 0.3);

    return MouseRegion(
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isEnabled ? onTap : null,
        child: SizedBox(
          width: touchSize,
          height: touchSize + (isLarge ? 20 : 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLight
                      ? Colors.white.withValues(alpha: isEnabled ? 0.6 : 0.3)
                      : Colors.white.withValues(alpha: isEnabled ? 0.2 : 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
              SizedBox(height: isLarge ? 4 : 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
