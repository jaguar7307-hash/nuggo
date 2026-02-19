import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final user = provider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('로그인이 필요합니다')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('계정'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => provider.setActiveView(ViewType.editor),
            ),
          ),
          body: ListView(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      backgroundImage: user.avatarUrl != null
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.membership.name == 'pro'
                            ? Colors.amber.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user.membership.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: user.membership.name == 'pro'
                              ? Colors.amber.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(),
              
              // Account Info
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('가입일'),
                subtitle: Text(user.joinedDate),
              ),
              
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('로그인 방식'),
                subtitle: Text(user.provider.name.toUpperCase()),
              ),
              
              if (user.membership.name == 'free') ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary),
                  title: const Text('오늘 보낸 명함'),
                  subtitle: Text('${user.sendsToday} / 10'),
                  trailing: ElevatedButton(
                    onPressed: () => provider.setPaymentModalOpen(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black87,
                    ),
                    child: const Text('Pro 업그레이드'),
                  ),
                ),
              ],
              
              const Divider(),
              
              // Actions
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('설정'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => provider.setActiveView(ViewType.settings),
              ),
              
              if (!user.isGuest)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('로그아웃'),
                        content: const Text('정말 로그아웃하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('로그아웃'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await provider.logout();
                    }
                  },
                ),
              
              if (!user.isGuest)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('계정 삭제', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('계정 삭제'),
                        content: const Text('계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await provider.deleteAccount();
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
