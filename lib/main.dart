import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/screens/profile_screen.dart';
import 'package:sayfa_yonlendirme/services/auth_service.dart';
import 'screens/login_page.dart';
import './db/database_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter uygulaması başlatılmadan önce asenkron işlemler yapılması gerekir
  await checkDatabase(); // Veritabanını kontrol et
  DatabaseHelper.instance.printTables(); // Veritabanındaki tüm tablolara bak
  runApp(MyApp()); // Uygulamayı başlat
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
    );
  }
}

// 🎯 Giriş durumunu kontrol eden wrapper
class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _savedUser;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      final savedUser = await AuthService.getSavedUser();
      
      setState(() {
        _isLoggedIn = isLoggedIn;
        _savedUser = savedUser;
        _isLoading = false;
      });
      
      if (isLoggedIn && savedUser != null) {
        print('🎯 Otomatik giriş: ${savedUser['username']} (ID: ${savedUser['userId']})');
        
        // Daily task'ları oluştur
        await DatabaseHelper.instance.generateDailyTasksForUser(savedUser['userId']);
      } else {
        print('🎯 Kullanıcı giriş yapmamış, login ekranına yönlendiriliyor');
      }
    } catch (e) {
      print('❌ Giriş durumu kontrol hatası: $e');
      setState(() {
        _isLoading = false;
        _isLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Loading ekranı
      return Scaffold(
        backgroundColor: Color(0xFF404040),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF984fff)),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoggedIn && _savedUser != null) {
      // Otomatik giriş - ProfileScreen'e git
      return ProfileScreen(userId: _savedUser!['userId']);
    } else {
      // Giriş yapılmamış - LoginPage'e git
      return LogInPage();
    }
  }
}

Future<void> checkDatabase() async {
  try {
    await DatabaseHelper.instance.database;  // Singleton instance üzerinden veritabanı erişimi    
    print('\n***\nVeritabanına başarıyla bağlanıldı!\n***\n');
  } catch (e) {
    print('\n***\nVeritabanına bağlanılamadı: $e\n***\n');
  }
}