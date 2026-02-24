import 'dart:convert';

import 'package:flutter/material.dart';
import '../models/card_data.dart';

/// 미리보기 화면과 동일한 명함 콘텐츠 구조. 내 명함·에디터·미리보기에서 공통 사용.
class PreviewCardContent extends StatelessWidget {
  final CardData data;
  final Color textColor;
  final Color subColor;
  final Color iconBg;
  final bool isLight;
  final void Function(String type, String value) onAction;
  final VoidCallback onPortfolio;
  final VoidCallback? onAddressTap;

  const PreviewCardContent({
    super.key,
    required this.data,
    required this.textColor,
    required this.subColor,
    required this.iconBg,
    required this.isLight,
    required this.onAction,
    required this.onPortfolio,
    this.onAddressTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
        if (data.slogan.isNotEmpty)
          Text(
            '"${data.slogan}"',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.0,
              decoration: TextDecoration.none,
              color: textColor.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (data.profileImage != null && data.profileImage!.isNotEmpty)
          SizedBox(
            width: 72,
            height: 72,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 128,
                height: 128,
                child: _buildProfileImage(data.profileImage!),
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.fullName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.0,
                decoration: TextDecoration.none,
                color: textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              data.jobTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                height: 1.0,
                decoration: TextDecoration.none,
                color: Color(0xFFd4b98c),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              data.companyName.toUpperCase(),
              style: TextStyle(
                fontSize: 7,
                letterSpacing: 1.5,
                height: 1.0,
                decoration: TextDecoration.none,
                color: textColor.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 3,
                      childAspectRatio: 1.05,
                      children: [
                        _actionItem(context, Icons.phone, 'PHONE', 'call', data.phone),
                        _actionItem(
                          context,
                          Icons.chat_bubble,
                          'MESSAGE',
                          'sms',
                          data.sms.isNotEmpty ? data.sms : data.phone,
                        ),
                        _actionItem(context, Icons.language, 'WEBSITE', 'language', data.website),
                        _actionItem(context, Icons.chat_outlined, 'KAKAO', 'forum', data.kakao),
                        _actionItem(context, Icons.share, 'SNS', 'share', data.shareLink),
                      ],
                    ),
                    const SizedBox(height: 2),
                    _portfolioItem(context),
                    if (data.address.isNotEmpty) ...[
                      const SizedBox(height: 2), // 상단 mainAxisSpacing 2와 동일
                      GestureDetector(
                        onTap: onAddressTap ?? () => onAction('map', data.address),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLight
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 8, color: textColor.withValues(alpha: 0.9)),
                              const SizedBox(width: 4),
                              Text(
                                data.address.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 6,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  height: 1.0,
                                  decoration: TextDecoration.none,
                                  color: textColor.withValues(alpha: 0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }


  Widget _actionItem(
    BuildContext context,
    IconData icon,
    String label,
    String type,
    String value,
  ) {
    const double touchSize = 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touchSize,
          height: touchSize,
          child: Material(
            color: iconBg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => onAction(type, value),
              customBorder: const CircleBorder(),
              splashColor: subColor.withValues(alpha: 0.2),
              highlightColor: subColor.withValues(alpha: 0.1),
              child: Center(child: Icon(icon, size: 20, color: subColor)),
            ),
          ),
        ),
        const SizedBox(height: 0),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.0,
            decoration: TextDecoration.none,
            color: subColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _portfolioItem(BuildContext context) {
    const double touchSize = 52;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: touchSize,
          height: touchSize,
          child: Material(
            color: iconBg,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPortfolio,
              customBorder: const CircleBorder(),
              splashColor: subColor.withValues(alpha: 0.2),
              highlightColor: subColor.withValues(alpha: 0.1),
              child: Center(child: Icon(Icons.folder_open, size: 20, color: subColor)),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '포트폴리오',
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.0,
            decoration: TextDecoration.none,
            color: subColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProfileImage(String url) {
    try {
      if (url.startsWith('data:')) {
        final bytes = base64Decode(url.split(',').last);
        return Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
              ),
            ],
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
      return Container(
        width: 128,
        height: 128,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
            ),
          ],
          image: DecorationImage(
            image: NetworkImage(url),
            fit: BoxFit.cover,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
