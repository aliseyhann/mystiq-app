import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _keyEmail = 'user_email';
  static const String _keyRole = 'user_role';
  static const String _keyLastLogin = 'last_login';
  static const int sessionDurationMinutes = 30;

  final SharedPreferences prefs;

  SessionService(this.prefs);

  Future<void> saveSession(String email, String role) async {
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
    await prefs.setInt(_keyLastLogin, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, String?>> getSession() async {
    final email = prefs.getString(_keyEmail);
    final role = prefs.getString(_keyRole);
    final lastLogin = prefs.getInt(_keyLastLogin);

    if (email != null && role != null && lastLogin != null) {
      final lastLoginTime = DateTime.fromMillisecondsSinceEpoch(lastLogin);
      final difference = DateTime.now().difference(lastLoginTime).inMinutes;

      if (difference <= sessionDurationMinutes) {
        // Oturum süresi geçerli, süreyi yenile
        await prefs.setInt(_keyLastLogin, DateTime.now().millisecondsSinceEpoch);
        return {'email': email, 'role': role};
      }
    }

    // Oturum süresi dolmuş veya bilgiler eksik, oturumu temizle
    await clearSession();
    return {'email': null, 'role': null};
  }

  Future<void> clearSession() async {
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyLastLogin);
  }
} 