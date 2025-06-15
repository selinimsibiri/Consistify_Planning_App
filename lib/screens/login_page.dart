import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';
import 'package:sayfa_yonlendirme/screens/profile_screen.dart';
import 'package:sayfa_yonlendirme/screens/signup_page.dart';
import 'package:sayfa_yonlendirme/screens/todo_screen.dart';
import 'package:sayfa_yonlendirme/services/auth_service.dart';
import 'package:sayfa_yonlendirme/utils/app_routes.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  void _tryLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final hash = sha256.convert(utf8.encode(password)).toString();

    print("Giriş yapılan email: $email, hash: $hash");

    final user = await DatabaseHelper.instance.loginUser(email, hash);

    if (user != null) {
      print("\n***\nHoş geldin ${user.username} 🧜‍♀️\nusername: ${user.username}\nemail: ${user.email}\nhash: ${user.passwordHash}\n***\n");

      // Giriş durumunu kaydediyoruz.
      await AuthService.saveLoginState(
        userId: user.id!,
        username: user.username,
        email: user.email,
      );

      await DatabaseHelper.instance.generateDailyTasksForUser(user.id!);

      // MarketSection yerine ProfileScreen'e yönlendir ve userId gönder:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TodoScreen(userId: user.id!), // userId'yi ProfileScreen'e gönder
        ),
      );
      
    } else {
      print("\n***\n❌ Giriş başarısız!\n***\n");
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız! Email veya şifre hatalı.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF404040),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              // Giriş başlığı
              Text(
                "Sign In to",
                style: TextStyle(
                  fontFamily: "CodecPro",
                  fontWeight: FontWeight.w600,
                  fontSize: 38,
                  letterSpacing: 0.8,
                  height: 0.8,
                  color: Color(0xFFFFFFFF), // Beyaz
                ),  
              ),
              Text(
                "Your Account",
                style: TextStyle(
                  fontFamily: "CodecPro",
                  fontWeight: FontWeight.w600,
                  fontSize: 40,
                  letterSpacing: 0.8,
                  height: 0.8,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.16),

              // email text
              Text(
                "EMAIL",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.4,
                  color: Color(0xFF3d8dff),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              // email textfield
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFececec),
                    border: Border.all(color: Color.fromARGB(255, 203, 203, 203)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: MediaQuery.of(context).size.height * 0.055,
                  child: TextField(
                    controller: _emailController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "yourmail@gmail.com",
                      hintStyle: TextStyle(
                        fontSize: 18,
                        letterSpacing: 1.4,
                        color: const Color.fromARGB(255, 115, 115, 115),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

                  // password text
                  Text(
                    "PASSWORD",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.4,
                      color: Color(0xFF3d8dff),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),

                  // password textfield
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFececec),
                        border: Border.all(color: const Color.fromARGB(255, 115, 115, 115)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      height: MediaQuery.of(context).size.height * 0.055,
                      child: TextField(
                        controller: _passwordController,
                        textAlign: TextAlign.center,
                        obscureText: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "*****",
                          hintStyle: TextStyle(
                            fontSize: 18,
                            letterSpacing: 1.4,
                            color: const Color.fromARGB(255, 115, 115, 115),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),

                  // forgot password
                  Center(
                    child: InkWell(
                      onTap: () async {
                        await generateTestData(1);
                      },
                      child:
                       Text(
                        "Forgot password?",
                        style: TextStyle(
                          color: Color(0xFF984fff),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.18),


                  // sign in button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: ElevatedButton(
                      onPressed: () {
                       _tryLogin();  // Burada _tryLogin fonksiyonunu çağırıyoruz,
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF984fff), // Mor renk
                        padding: EdgeInsets.all(18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Sign in",
                          style: TextStyle(
                            color: Colors.white, // Yazı rengi beyaz
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                  // register now
                  Column(
                    children: [
                      Text(
                        "You don't have an account?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          // yonlendirme
                          Navigator.push(
                            context,
                            AppRoutes.createRoute(
                              SignUpPage(),
                              type: RouteType.fade,
                            ),
                          );
                        },
                        child: Text(
                          "Sign up here!",
                          style: TextStyle(
                            color: Color(0xFF3d8dff),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
          ),
    );
  }

  Future<void> generateTestData(int userId) async {
    try {
      final db = await _databaseHelper.database;
      final random = Random();
      final now = DateTime.now();
      
      // Önce mevcut verileri temizle
      await db.delete('user_stats', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('tasks', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('streaks', where: 'user_id = ?', whereArgs: [userId]);
      await db.delete('daily_templates', where: 'user_id = ?', whereArgs: [userId]);
      
      // Kullanıcının var olduğundan emin olalım
      final userExists = await db.query('users', where: 'id = ?', whereArgs: [userId]);
      if (userExists.isEmpty) {
        await db.insert('users', {
          'id': userId,
          'username': 'testuser',
          'email': 'test@example.com',
          'password_hash': 'hashedpassword123',
          'coins': 500,
          'created_at': now.subtract(Duration(days: 70)).toIso8601String()
        });
        print('✅ Test kullanıcısı oluşturuldu');
      } else {
        print('✅ Test kullanıcısı zaten mevcut');
      }
      
      // Günlük şablonlar oluştur
      List<int> dailyTemplateIds = [];
      List<String> dailyTitles = [
        'Sabah Sporu', 
        'Su İçmek', 
        'Okuma Zamanı', 
        'Meditasyon', 
        'Kod Yazma Pratiği'
      ];
      
      for (var title in dailyTitles) {
        final id = await db.insert('daily_templates', {
          'user_id': userId,
          'title': title,
          'description': '$title için günlük hatırlatma',
          'selected_days': '1,2,3,4,5,6,7', // Her gün
          'coin_reward': 5 + random.nextInt(10),
          'is_active': 1,
          'created_at': now.subtract(Duration(days: 65)).toIso8601String()
        });
        dailyTemplateIds.add(id);
      }
      print('✅ ${dailyTemplateIds.length} adet günlük şablon oluşturuldu');
      
      // One-time görevler için başlıklar
      List<String> oneTimeTitles = [
        'Alışveriş Yap',
        'Fatura Öde',
        'Rapor Hazırla',
        'Kitap Bitir',
        'Proje Teslim Et',
        'Ev Temizliği',
        'Aile Ziyareti',
        'Diş Hekimi Randevusu',
        'Araba Bakımı',
        'Doğum Günü Hediyesi Al'
      ];
      
      int totalTasksCreated = 0;
      int totalStatsCreated = 0;
      int totalStreaksCreated = 0;
      
      // Son 60 gün için veriler oluştur
      for (int i = 60; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        
        // Her gün için 1-3 one-time görev ekle
        int oneTimeTaskCount = 1 + random.nextInt(3);
        int completedOneTimeCount = 0;
        
        for (int j = 0; j < oneTimeTaskCount; j++) {
          final title = oneTimeTitles[random.nextInt(oneTimeTitles.length)];
          final isCompleted = random.nextDouble() > 0.3 ? 1 : 0; // %70 tamamlanma olasılığı
          
          if (isCompleted == 1) {
            completedOneTimeCount++;
          }
          
          await db.insert('tasks', {
            'user_id': userId,
            'title': '$title - $dateStr',
            'description': 'Bu bir test görevidir',
            'type': 'one_time',
            'coin_reward': 10 + random.nextInt(15),
            'is_active': 1,
            'is_completed': isCompleted,
            'created_at': dateStr
          });
          totalTasksCreated++;
        }
        
        // Her gün için daily template'lerden görevler oluştur
        int dailyTaskCount = 0;
        int completedDailyCount = 0;
        
        for (var templateId in dailyTemplateIds) {
          // Her şablon için %80 olasılıkla görev oluştur
          if (random.nextDouble() < 0.8) {
            dailyTaskCount++;
            final isCompleted = random.nextDouble() > 0.2 ? 1 : 0; // %80 tamamlanma olasılığı
            
            if (isCompleted == 1) {
              completedDailyCount++;
            }
            
            await db.insert('tasks', {
              'user_id': userId,
              'title': dailyTitles[dailyTemplateIds.indexOf(templateId)],
              'description': 'Günlük görev',
              'type': 'daily',
              'daily_template_id': templateId,
              'coin_reward': 5 + random.nextInt(5),
              'is_active': 1,
              'is_completed': isCompleted,
              'created_at': dateStr
            });
            totalTasksCreated++;
          }
        }
        
        // Toplam görev sayısı
        final totalTasks = oneTimeTaskCount + dailyTaskCount;
        final completedTasks = completedOneTimeCount + completedDailyCount;
        final completionRate = totalTasks > 0 ? (completedTasks * 100.0 / totalTasks) : 0.0;
        
        // Kazanılan coinler (tamamlanan görev başına 5-15 coin)
        final coinsEarned = completedTasks * (5 + random.nextInt(10));
        
        // Streak hesapla (son 7 günde en az 1 görev tamamlanmışsa streak devam eder)
        int streakCount = 0;
        if (i <= 7) {
          // Basit bir streak hesaplama - gerçek uygulamada daha karmaşık olabilir
          streakCount = min(7 - i, 7); // Son 7 gün için artan streak
        } else {
          streakCount = random.nextInt(7); // Rastgele streak değeri
        }
        
        // User stats tablosuna günlük istatistikleri ekle
        // Önce bu tarih için kayıt var mı kontrol et
        final existingStats = await db.query('user_stats', 
            where: 'user_id = ? AND date = ?', 
            whereArgs: [userId, dateStr]);
        
        if (existingStats.isEmpty) {
          await db.insert('user_stats', {
            'user_id': userId,
            'date': dateStr,
            'total_tasks': totalTasks,
            'completed_tasks': completedTasks,
            'completion_rate': completionRate,
            'daily_tasks': dailyTaskCount,
            'onetime_tasks': oneTimeTaskCount,
            'streak_count': streakCount,
            'coins_earned': coinsEarned,
            'created_at': dateStr
          });
          totalStatsCreated++;
        }
        
        // Streak tablosuna da ekle
        if (completedTasks > 0) {
          final existingStreak = await db.query('streaks',
              where: 'user_id = ? AND date = ?',
              whereArgs: [userId, dateStr]);
              
          if (existingStreak.isEmpty) {
            await db.insert('streaks', {
              'user_id': userId,
              'date': dateStr,
              'completed_tasks': completedTasks
            });
            totalStreaksCreated++;
          }
        }
      }
      
      print('✅ Test verileri başarıyla oluşturuldu!');
      print('📊 Oluşturulan görev sayısı: $totalTasksCreated');
      print('📊 Oluşturulan istatistik kaydı sayısı: $totalStatsCreated');
      print('📊 Oluşturulan streak kaydı sayısı: $totalStreaksCreated');
      
    } catch (e) {
      print('❌ Test verisi oluşturma hatası: $e');
    }
  }


}
