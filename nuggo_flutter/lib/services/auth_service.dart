import '../models/user.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storage = StorageService();

  // Guest Login
  Future<User> loginAsGuest() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return User(
      email: 'guest@tapcard.app',
      name: 'Guest',
      joinedDate: today,
      provider: AuthProvider.guest,
      isGuest: true,
      membership: MembershipTier.free,
      sendsToday: 0,
      lastSendDate: today,
    );
  }

  // Email Sign Up
  Future<User> signUpWithEmail(String email, String password, String name) async {
    final users = await _storage.getUsers();
    
    if (users.any((u) => u.email == email)) {
      throw Exception("이미 가입된 이메일 주소입니다.");
    }

    final today = DateTime.now().toIso8601String().split('T')[0];
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final newUser = User(
      email: email,
      name: name,
      password: password,
      joinedDate: today,
      provider: AuthProvider.email,
      membership: MembershipTier.free,
      sendsToday: 0,
      lastSendDate: today,
      accessToken: 'access_${now}_$email',
      lastLoginAt: now,
    );

    users.add(newUser);
    await _storage.saveUsers(users);
    await _storage.saveSession(email, newUser.accessToken!);

    return newUser;
  }

  // Email Login
  Future<User> loginWithEmail(String email, String password) async {
    final users = await _storage.getUsers();
    
    final user = users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception("가입되지 않은 이메일입니다."),
    );

    if (user.provider != AuthProvider.email || user.password == null) {
      throw Exception("${user.provider.name}로 가입된 계정입니다.");
    }

    if (user.password != password) {
      throw Exception("비밀번호가 일치하지 않습니다.");
    }

    // Update login time
    final now = DateTime.now().millisecondsSinceEpoch;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final updatedUser = user.copyWith(
      lastLoginAt: now,
      accessToken: 'access_${now}_$email',
      sendsToday: user.lastSendDate != today ? 0 : user.sendsToday,
      lastSendDate: today,
    );

    // Update in storage
    final index = users.indexWhere((u) => u.email == email);
    users[index] = updatedUser;
    await _storage.saveUsers(users);
    await _storage.saveSession(email, updatedUser.accessToken!);

    return updatedUser;
  }

  // Social Login
  Future<User> loginWithSocial(
    String email,
    String name,
    AuthProvider provider, {
    String? avatarUrl,
  }) async {
    final users = await _storage.getUsers();
    final now = DateTime.now().millisecondsSinceEpoch;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    User user;
    final existingUser = users.where((u) => u.email == email).firstOrNull;
    
    if (existingUser == null) {
      // New social user
      user = User(
        email: email,
        name: name,
        joinedDate: today,
        provider: provider,
        avatarUrl: avatarUrl,
        membership: MembershipTier.free,
        sendsToday: 0,
        lastSendDate: today,
        accessToken: 'access_${now}_$email',
        lastLoginAt: now,
      );
      users.add(user);
    } else {
      // Existing user
      user = existingUser.copyWith(
        lastLoginAt: now,
        accessToken: 'access_${now}_$email',
        avatarUrl: avatarUrl ?? existingUser.avatarUrl,
        sendsToday: existingUser.lastSendDate != today ? 0 : existingUser.sendsToday,
        lastSendDate: today,
      );
      
      final index = users.indexWhere((u) => u.email == email);
      users[index] = user;
    }

    await _storage.saveUsers(users);
    await _storage.saveSession(email, user.accessToken!);

    return user;
  }

  // Restore Session
  Future<User?> restoreSession() async {
    final session = await _storage.getSession();
    final sessionEmail = session['email'];
    final token = session['token'];

    if (sessionEmail == null || token == null) {
      return null;
    }

    final users = await _storage.getUsers();
    final user = users.where((u) => u.email == sessionEmail).firstOrNull;

    if (user == null) {
      await _storage.clearSession();
      return null;
    }

    // Check token expiry (24h)
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastLogin = user.lastLoginAt ?? 0;
    
    if (now - lastLogin > 24 * 60 * 60 * 1000) {
      // Token expired
      await _storage.clearSession();
      return null;
    }

    // Update daily limit if day changed
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (user.lastSendDate != today) {
      final updatedUser = user.copyWith(
        sendsToday: 0,
        lastSendDate: today,
      );
      
      final index = users.indexWhere((u) => u.email == sessionEmail);
      users[index] = updatedUser;
      await _storage.saveUsers(users);
      
      return updatedUser;
    }

    return user;
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearSession();
  }

  // Delete Account
  Future<void> deleteAccount(String email) async {
    final users = await _storage.getUsers();
    users.removeWhere((u) => u.email == email);
    await _storage.saveUsers(users);
    await _storage.clearSession();
  }

  // Update User
  Future<void> updateUser(User user) async {
    final users = await _storage.getUsers();
    final index = users.indexWhere((u) => u.email == user.email);
    
    if (index != -1) {
      users[index] = user;
      await _storage.saveUsers(users);
    }
  }
}
