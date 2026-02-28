import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/app_provider.dart';

class LoginBottomSheet extends StatelessWidget {
  const LoginBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const LoginBottomSheet(),
    );
  }

  Future<void> _loginSocial(
    BuildContext context, {
    required AuthProvider provider,
    required String email,
    required String name,
  }) async {
    final app = context.read<AppProvider>();
    try {
      await app.handleAuth(
        type: 'social',
        provider: provider,
        email: email,
        name: name,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인되었습니다.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그인 실패: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return SafeArea(
      top: false,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '로그인 / 회원가입',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: subColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '게스트는 공유/보내기 1회만 체험할 수 있어요.',
                  style: TextStyle(fontSize: 12, color: subColor),
                ),
              ),
              const SizedBox(height: 14),
              _LoginButton(
                label: 'Apple로 계속하기',
                onTap: () => _loginSocial(
                  context,
                  provider: AuthProvider.apple,
                  email: 'apple_user@nuggo.me',
                  name: 'Apple 사용자',
                ),
                background: Colors.black,
                foreground: Colors.white,
                icon: Icons.phone_iphone_rounded,
              ),
              const SizedBox(height: 10),
              _LoginButton(
                label: 'Google로 계속하기',
                onTap: () => _loginSocial(
                  context,
                  provider: AuthProvider.google,
                  email: 'google_user@nuggo.me',
                  name: 'Google 사용자',
                ),
                background: const Color(0xFF4285F4),
                foreground: Colors.white,
                icon: Icons.g_mobiledata_rounded,
              ),
              const SizedBox(height: 10),
              _LoginButton(
                label: '네이버로 계속하기',
                onTap: () => _loginSocial(
                  context,
                  provider: AuthProvider.naver,
                  email: 'naver_user@nuggo.me',
                  name: '네이버 사용자',
                ),
                background: const Color(0xFF03C75A),
                foreground: Colors.white,
                icon: Icons.public,
              ),
              const SizedBox(height: 10),
              _LoginButton(
                label: '카카오로 계속하기',
                onTap: () => _loginSocial(
                  context,
                  provider: AuthProvider.kakao,
                  email: 'kakao_user@nuggo.me',
                  name: '카카오 사용자',
                ),
                background: const Color(0xFFFFE000),
                foreground: Colors.black87,
                icon: Icons.chat_bubble_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _LoginButton({
    required this.label,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

