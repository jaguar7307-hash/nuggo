import 'package:flutter/material.dart';
import '../models/card_data.dart';
import '../constants/theme.dart';

/// 명함 비율 상수 (242.55 : 388.08 = 1 : 1.6)
const double kBusinessCardAspectWidth = 242.55;
const double kBusinessCardAspectHeight = 388.08;
const double kBusinessCardAspectRatio =
    kBusinessCardAspectWidth / kBusinessCardAspectHeight;

/// 두 페이지(내 명함·에디터)에서 동일하게 사용하는 공통 명함 위젯.
/// SizedBox.expand()로 부모 크기를 100% 사용. 고정 크기/AspectRatio/FittedBox 제거.
class BusinessCard extends StatelessWidget {
  final CardData data;
  final VoidCallback? onAddressClick;
  final void Function(String type, String value)? onAction;

  const BusinessCard({
    super.key,
    required this.data,
    this.onAddressClick,
    this.onAction,
  });

  bool get _isHexTheme => data.theme.startsWith('#');

  bool get _isLightBackground {
    if (!_isHexTheme) return false;
    final hex = data.theme.replaceAll('#', '');
    final fullHex =
        hex.length == 3 ? hex.split('').map((c) => '$c$c').join('') : hex;
    final r = int.tryParse(fullHex.substring(0, 2), radix: 16) ?? 0;
    final g = int.tryParse(fullHex.substring(2, 4), radix: 16) ?? 0;
    final b = int.tryParse(fullHex.substring(4, 6), radix: 16) ?? 0;
    final yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
    return yiq >= 128;
  }

  Color _parseHexColor(String hex) {
    final hexCode = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  void _handleTap(String type, String value) {
    onAction?.call(type, value);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _isLightBackground ? Colors.black87 : Colors.white;
    final accentColor = _isLightBackground
        ? AppTheme.primary
        : Colors.white.withValues(alpha: 0.8);
    final hasProfileImage =
        data.profileImage != null && data.profileImage!.isNotEmpty;

    return SizedBox.expand(
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
          fit: StackFit.expand,
          clipBehavior: Clip.antiAlias,
          children: [
            if (!_isHexTheme)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTopSection(
                    context,
                    textColor: textColor,
                    hasProfileImage: hasProfileImage,
                  ),
                  _buildIdentitySection(
                    textColor: textColor,
                    accentColor: accentColor,
                  ),
                  _buildBottomSection(
                    context,
                    textColor: textColor,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(
    BuildContext context, {
    required Color textColor,
    required bool hasProfileImage,
  }) {
    final hasSlogan = data.slogan.trim().isNotEmpty;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            hasProfileImage
                ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                      image: DecorationImage(
                        image: data.profileImage!.startsWith('http')
                            ? NetworkImage(data.profileImage!)
                            : MemoryImage(
                                Uri.parse(data.profileImage!).data!.contentAsBytes(),
                              ) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '"${data.slogan}"',
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            if (hasProfileImage && hasSlogan) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '"${data.slogan}"',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIdentitySection({
    required Color textColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.fullName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            data.jobTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.companyName.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
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
    );
  }

  Widget _buildBottomSection(
    BuildContext context, {
    required Color textColor,
    required Color accentColor,
  }) {
    final isLight = _isLightBackground;
    final iconColor = isLight ? Colors.black87 : Colors.white;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.phone,
                    label: 'PHONE',
                    enabled: data.phone.isNotEmpty,
                    color: iconColor,
                    onTap: () => _handleTap('call', data.phone),
                  ),
                ),
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.chat_bubble,
                    label: 'MESSAGE',
                    enabled: data.sms.isNotEmpty,
                    color: iconColor,
                    onTap: () => _handleTap(
                      'sms',
                      data.sms.isNotEmpty ? data.sms : data.phone,
                    ),
                  ),
                ),
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.mail,
                    label: 'EMAIL',
                    enabled: data.email.isNotEmpty,
                    color: iconColor,
                    onTap: () => _handleTap('mail', data.email),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.language,
                    label: 'WEBSITE',
                    enabled: data.website.isNotEmpty,
                    color: iconColor,
                    onTap: () => _handleTap('website', data.website),
                  ),
                ),
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.chat_outlined,
                    label: 'KAKAO',
                    enabled: data.kakao.isNotEmpty,
                    color: iconColor,
                    onTap: () => _handleTap('kakao', data.kakao),
                  ),
                ),
                Expanded(
                  child: _ActionIcon(
                    icon: Icons.share,
                    label: 'SNS',
                    enabled: true,
                    color: iconColor,
                    onTap: () => _handleTap('share', ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            _ActionIcon(
              icon: Icons.folder_open,
              label: '포트폴리오',
              enabled: ((data.portfolioUrl ?? '').isNotEmpty ||
                  (data.portfolioFile ?? '').isNotEmpty),
              color: iconColor,
              onTap: () => _handleTap(
                'portfolio',
                (data.portfolioUrl ?? '').trim(),
              ),
            ),
            if (data.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onAddressClick,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 9,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data.address.toUpperCase(),
                          style: TextStyle(
                            fontSize: 7,
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
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color.withValues(alpha: enabled ? 1 : 0.3);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: enabled ? 0.3 : 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
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
