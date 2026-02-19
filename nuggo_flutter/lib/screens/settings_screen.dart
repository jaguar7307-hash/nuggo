import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final settings = provider.settings;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('설정'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => provider.setActiveView(ViewType.editor),
            ),
          ),
          body: ListView(
            children: [
              _buildSection(
                title: '외관',
                children: [
                  SwitchListTile(
                    title: const Text('다크 모드'),
                    subtitle: const Text('어두운 테마 사용'),
                    value: settings.darkMode,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(darkMode: value));
                    },
                  ),
                ],
              ),
              
              _buildSection(
                title: '알림',
                children: [
                  SwitchListTile(
                    title: const Text('알림'),
                    subtitle: const Text('푸시 알림 수신'),
                    value: settings.notifications,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(notifications: value));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('마케팅'),
                    subtitle: const Text('마케팅 정보 수신'),
                    value: settings.marketing,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(marketing: value));
                    },
                  ),
                ],
              ),
              
              _buildSection(
                title: '보안',
                children: [
                  SwitchListTile(
                    title: const Text('생체 인증'),
                    subtitle: const Text('앱 잠금 사용'),
                    value: settings.biometrics,
                    onChanged: (value) {
                      if (value && provider.currentUser?.lockPin == null) {
                        // TODO: Show PIN setup
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('먼저 PIN을 설정해주세요')),
                        );
                        return;
                      }
                      provider.updateSettings(settings.copyWith(biometrics: value));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('프라이빗 모드'),
                    subtitle: const Text('비공개 모드'),
                    value: settings.privateMode,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(privateMode: value));
                    },
                  ),
                ],
              ),
              
              _buildSection(
                title: '기타',
                children: [
                  SwitchListTile(
                    title: const Text('사운드'),
                    subtitle: const Text('효과음 재생'),
                    value: settings.sound,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(sound: value));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('햅틱'),
                    subtitle: const Text('진동 피드백'),
                    value: settings.haptic,
                    onChanged: (value) {
                      provider.updateSettings(settings.copyWith(haptic: value));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}
