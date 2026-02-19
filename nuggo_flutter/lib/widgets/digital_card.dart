import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_data.dart';
import '../constants/theme.dart';

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

  Future<void> _handleAction(BuildContext context, String type, String value) async {
    if (value.isEmpty && type != 'share') return;

    if (type == 'share') {
      String shareUrl = data.shareLink.trim().isEmpty ? 'https://nuggo.me' : data.shareLink;
      if (!shareUrl.startsWith('http')) shareUrl = 'https://$shareUrl';
      await Share.share(shareUrl, subject: '명함: ${data.fullName.isNotEmpty ? data.fullName : "NUGGO"}');
      return;
    }

    final Uri? uri;
    switch (type) {
      case 'call':
        uri = Uri(scheme: 'tel', path: value);
        break;
      case 'sms':
        uri = Uri(scheme: 'sms', path: value);
        break;
      case 'mail':
        uri = Uri(scheme: 'mailto', path: value);
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
        uri = Uri.parse('https://search.naver.com/search.naver?query=$value');
        break;
      default:
        uri = null;
    }

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isLightBackground ? Colors.black87 : Colors.white;
    final accentColor = _isLightBackground ? AppTheme.primary : Colors.white.withValues(alpha: 0.8);
    
    return AspectRatio(
      aspectRatio: 1 / 1.6,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: _isHexTheme ? _parseHexColor(data.theme) : const Color(0xFF1a1c1e),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
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
            Padding(
              padding: EdgeInsets.all(isLarge ? 32.0 : 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile Image or Slogan
                  if (data.profileImage != null)
                    Container(
                      width: isLarge ? 96 : 48,
                      height: isLarge ? 96 : 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                        image: DecorationImage(
                          image: data.profileImage!.startsWith('http')
                              ? NetworkImage(data.profileImage!)
                              : MemoryImage(Uri.parse(data.profileImage!).data!.contentAsBytes()) as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: isLarge ? 32 : 6),
                        Container(
                          width: 20,
                          height: 1,
                          color: textColor.withValues(alpha: 0.4),
                        ),
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
                          mainAxisSpacing: isLarge ? 8 : 4,
                          crossAxisSpacing: isLarge ? 8 : 4,
                          childAspectRatio: isLarge ? 0.8 : 0.92,
                        ),
                        children: [
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(icon: Icons.phone, label: 'PHONE', isEnabled: data.phone.isNotEmpty, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'call', data.phone)),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(icon: Icons.chat_bubble, label: 'MESSAGE', isEnabled: data.sms.isNotEmpty, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'sms', data.sms)),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? 4.0 : 2.0),
                            child: _CardActionItem(icon: Icons.mail, label: 'EMAIL', isEnabled: data.email.isNotEmpty, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'mail', data.email)),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(icon: Icons.language, label: 'WEBSITE', isEnabled: data.website.isNotEmpty, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'website', data.website)),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(icon: Icons.chat_outlined, label: 'KAKAO', isEnabled: data.kakao.isNotEmpty, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'kakao', data.kakao)),
                          ),
                          Transform.translate(
                            offset: Offset(0, isLarge ? -4.0 : -2.0),
                            child: _CardActionItem(icon: Icons.share, label: 'SNS', isEnabled: true, isLight: _isLightBackground, isLarge: isLarge, onTap: () => _handleAction(context, 'share', '')),
                          ),
                        ],
                      ),

                      SizedBox(height: isLarge ? 6 : 2),
                      _CardActionItem(
                        icon: Icons.folder_open,
                        label: '포트폴리오',
                        isEnabled: (data.portfolioUrl ?? '').isNotEmpty,
                        isLight: _isLightBackground,
                        isLarge: isLarge,
                        onTap: () => _handleAction(context, 'portfolio', data.portfolioUrl ?? ''),
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
    final circleSize = isLarge ? 38.0 : 26.0;
    final iconSize = isLarge ? 17.0 : 12.0;
    final textSize = isLarge ? 7.0 : 5.0;
    final touchSize = isLarge ? 56.0 : 44.0;
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
          height: touchSize + (isLarge ? 20 : 14),
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
                child: Icon(
                  icon,
                  size: iconSize,
                  color: iconColor,
                ),
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
