import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import './db/database_helper.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter uygulaması başlatılmadan önce asenkron işlemler yapılması gerekir
  await checkDatabase(); // Veritabanını kontrol et
  runApp(MyApp()); // Uygulamayı başlat
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LogInPage(),
    );
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