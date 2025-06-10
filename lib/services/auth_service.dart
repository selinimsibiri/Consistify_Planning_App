import 'package:shared_preferences/shared_preferences.dart';
//giriş yapılan kullanıcının uygulamayı her açtığında tekrar giriş yapmadan kayıtlı şekilde kullanabilmesi için auth servise dosyası burada.
class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _emailKey = 'email';

  // 🎯 Kullanıcı giriş yaptığında çağır
  static Future<void> saveLoginState({
    required int userId,
    required String username,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setInt(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_emailKey, email);
    
    print('✅ Giriş durumu kaydedildi: User ID $userId');
  }

  // 🎯 Kullanıcı çıkış yaptığında çağır
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_emailKey);
    
    print('✅ Çıkış yapıldı, giriş durumu temizlendi');
  }

  // 🎯 Kullanıcı giriş yapmış mı kontrol et
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // 🎯 Kayıtlı kullanıcı bilgilerini al
  static Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    
    if (!isLoggedIn) return null;
    
    return {
      'userId': prefs.getInt(_userIdKey),
      'username': prefs.getString(_usernameKey),
      'email': prefs.getString(_emailKey),
    };
  }
}
