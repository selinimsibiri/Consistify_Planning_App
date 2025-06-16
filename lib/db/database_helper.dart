import 'dart:io';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sayfa_yonlendirme/models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  /* DATABASE FONKSIYONLARI BAŞLANGICI */
  Future<Database> get database async {
      // Veritabanı zaten oluşturulmuşsa, mevcut instance'ı döndür.
      if (_database != null) return _database!;
      
      // Veritabanı henüz oluşturulmamışsa, _initDB fonksiyonu ile oluşturulacak.
      _database = await _initDB('todo_app.db');
      return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          coins INTEGER DEFAULT 0,
          created_at TEXT DEFAULT (datetime('now'))
      );
      ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        total_tasks INTEGER DEFAULT 0,
        completed_tasks INTEGER DEFAULT 0,
        completion_rate REAL DEFAULT 0.0,
        daily_tasks INTEGER DEFAULT 0,
        onetime_tasks INTEGER DEFAULT 0,
        streak_count INTEGER DEFAULT 0,
        coins_earned INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, date)
      )
    ''');
      
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT NOT NULL CHECK (type IN ('one_time', 'daily')),
        coin_reward INTEGER DEFAULT 5,
        daily_template_id INTEGER,
        is_active INTEGER DEFAULT 1,
        is_completed INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (daily_template_id) REFERENCES daily_templates (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        selected_days TEXT NOT NULL,
        coin_reward INTEGER DEFAULT 5,
        is_active INTEGER DEFAULT 1,
        last_generated_date TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    '''); // 🎯 "re" kaldırıldı
      
    await db.execute('''
      CREATE TABLE task_completion (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER,
          completed_at TEXT DEFAULT (datetime('now')),
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
      );
      ''');
      
    await db.execute('''
      CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon_path TEXT NOT NULL
      );
      ''');
      
    await db.execute('''
      CREATE TABLE shop_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category_id INTEGER NOT NULL,
          price INTEGER NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories(id)
      );
      ''');
      
    await db.execute('''
      CREATE TABLE user_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          item_id INTEGER,
          purchased_at TEXT DEFAULT (datetime('now')),
          FOREIGN KEY (user_id) REFERENCES users(id),
          FOREIGN KEY (item_id) REFERENCES shop_items(id)
      );
      ''');
      
    await db.execute('''
      CREATE TABLE streaks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          date TEXT NOT NULL,
          completed_tasks INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      );
      ''');

    await db.execute('''
      CREATE TABLE user_selected_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          item_id INTEGER,
          FOREIGN KEY (user_id) REFERENCES users(id),
          FOREIGN KEY (item_id) REFERENCES shop_items(id)
      );
      ''');

    await db.execute('''
      CREATE TABLE daily_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        plan_date TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, plan_date, time_slot)
      )
    ''');

    await db.execute('''
      CREATE TABLE plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        time_slot TEXT NOT NULL,
        date TEXT NOT NULL, 
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 🆕 Plan-Task ilişki tablosu
    await db.execute('''
      CREATE TABLE plan_tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        task_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (plan_id) REFERENCES plans (id) ON DELETE CASCADE,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
        UNIQUE(plan_id, task_id)
      )
    ''');

    // 🏆 GENEL BAŞARIMLAR TABLOSU (user_id YOK!)
    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT,
        condition_type TEXT NOT NULL,
        condition_value INTEGER NOT NULL,
        coin_reward INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 🏆 KULLANICI BAŞARIMLARI TABLOSU
    await db.execute('''
      CREATE TABLE user_achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        achievement_id INTEGER NOT NULL,
        earned_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (achievement_id) REFERENCES achievements (id) ON DELETE CASCADE,
        UNIQUE(user_id, achievement_id)
      )
    ''');
    
    await insertInitialData(db);
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
  }

  Future<void> insertInitialData(Database db) async {
    // Kategoriler tablosu doldurulmuş mu kontrol et, dolu değilse bir kerelik tüm dataları insert et.
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM categories'),
    );

    if (count != null && count > 0) {
      print("Initial data already exists. Skipping insert.");
      return;
    }

    // Insert Categories
    await db.insert('categories', {'name': 'body', 'icon_path': 'assets/category_icons/body.png'});
    await db.insert('categories', {'name': 'eyes', 'icon_path': 'assets/category_icons/eyes.png'});
    await db.insert('categories', {'name': 'mouth', 'icon_path': 'assets/category_icons/mouth.png'});
    await db.insert('categories', {'name': 'hair', 'icon_path': 'assets/category_icons/hair.png'}); //3
    await db.insert('categories', {'name': 'top', 'icon_path': 'assets/category_icons/top.png'}); //4
    await db.insert('categories', {'name': 'bottom', 'icon_path': 'assets/category_icons/bottom.png'}); //5
    await db.insert('categories', {'name': 'shoes', 'icon_path': 'assets/category_icons/shoes.png'}); //6
    await db.insert('categories', {'name': 'accs', 'icon_path': 'assets/category_icons/accs.png'}); //7
    await db.insert('categories', {'name': 'hat', 'icon_path': 'assets/category_icons/hat.png'}); //8

    // Insert Shop Items - BODY (category_id: 1) ⭐
    await db.insert('shop_items', {'name': 'body1', 'category_id': 1, 'price': 5});
    await db.insert('shop_items', {'name': 'body2', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body3', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body4', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body5', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body6', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body7', 'category_id': 1, 'price': 10});

    // Insert Shop Items - EYES (category_id: 2) ⭐
    await db.insert('shop_items', {'name': 'eyes1', 'category_id': 2, 'price': 5});
    await db.insert('shop_items', {'name': 'eyes2', 'category_id': 2, 'price': 10});
    await db.insert('shop_items', {'name': 'eyes3', 'category_id': 2, 'price': 10});
    await db.insert('shop_items', {'name': 'eyes4', 'category_id': 2, 'price': 10});
    await db.insert('shop_items', {'name': 'eyes5', 'category_id': 2, 'price': 10});
    await db.insert('shop_items', {'name': 'eyes6', 'category_id': 2, 'price': 10});
    await db.insert('shop_items', {'name': 'eyes7', 'category_id': 2, 'price': 10});

    // Insert Shop Items - HAIR (category_id: 4) ⭐
    await db.insert('shop_items', {'name': 'hair1', 'category_id': 4, 'price': 5});
    await db.insert('shop_items', {'name': 'hair2', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair3', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair4', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair5', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair6', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair7', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair8', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair9', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair10', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair11', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair12', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair13', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair14', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair15', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair16', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair17', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair18', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair19', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair20', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair21', 'category_id': 4, 'price': 10});
    await db.insert('shop_items', {'name': 'hair22', 'category_id': 4, 'price': 10});

    // Insert Shop Items - TOPS (category_id: 5) ⭐
    await db.insert('shop_items', {'name': 'top1', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top2', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top3', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top4', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top5', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top6', 'category_id': 5, 'price': 5});
    
    // Insert Shop Items - BOTTOM (category_id: 6) ⭐
    await db.insert('shop_items', {'name': 'bottom1', 'category_id': 6, 'price': 5});
    await db.insert('shop_items', {'name': 'bottom2', 'category_id': 6, 'price': 5});
    await db.insert('shop_items', {'name': 'bottom3', 'category_id': 6, 'price': 5});
    
    // Insert Shop Items - SHOES (category_id: 7) ⭐
    await db.insert('shop_items', {'name': 'shoes1', 'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes2',   'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes3', 'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes4', 'category_id': 7, 'price': 5});

    print("✅ Initial data inserted!");
  }

  Future<void> exportDatabaseToJson() async {
    try {
      final db = await database;
      
      // Tüm tabloları sorgula
      final users = await db.query('users');
      final tasks = await db.query('tasks');
      final dailyTemplates = await db.query('daily_templates');
      final taskCompletion = await db.query('task_completion');
      final categories = await db.query('categories');
      final shopItems = await db.query('shop_items');
      final userItems = await db.query('user_items');
      final streaks = await db.query('streaks');
      final userSelectedItems = await db.query('user_selected_items');
      final plans = await db.query('plans');      
      final planTasks = await db.query('plan_tasks');
      final userStats = await db.query('user_stats');
      final achievements = await db.query('achievements');
      final userAchievements = await db.query('user_achievements');
      
      final databaseSnapshot = {
        'export_time': DateTime.now().toString(),
        'database_version': 9,
        'tables': {
          'users': users,
          'tasks': tasks,
          'daily_templates': dailyTemplates,
          'task_completion': taskCompletion,
          'categories': categories,
          'shop_items': shopItems,
          'user_items': userItems,
          'streaks': streaks,
          'user_selected_items': userSelectedItems,
          'plans': plans,
          'plan_tasks': planTasks,
          'user_stats': userStats,
          'achievements': achievements,
          'user_achievements': userAchievements,
        },
        'summary': {
          // Istatistikler
          'total_users': users.length,
          'total_tasks': tasks.length,
          'active_tasks': tasks.where((t) => t['is_active'] == 1).length,
          'completed_tasks': tasks.where((t) => t['is_completed'] == 1).length,
          'total_daily_templates': dailyTemplates.length,
          'active_daily_templates': dailyTemplates.where((dt) => dt['is_active'] == 1).length,
          'total_completions': taskCompletion.length,
          'total_categories': categories.length,
          'total_shop_items': shopItems.length,
          'total_user_items': userItems.length,
          'total_streaks': streaks.length,
          'total_selected_items': userSelectedItems.length,
          'total_plans': plans.length,          
          'total_plan_tasks': planTasks.length,
          'total_user_stats': userStats.length,
          'total_achievements': achievements.length,
          'total_user_achievements': userAchievements.length,
          
          // DETAYLI ANALİZ
          'user_analysis': users.map((user) {
            final userId = user['id'];
            final userTaskCount = tasks.where((t) => t['user_id'] == userId).length;
            final userCompletedTasks = tasks.where((t) => t['user_id'] == userId && t['is_completed'] == 1).length;
            final userPlans = plans.where((p) => p['user_id'] == userId).length;
            final userStatsRecord = userStats.where((s) => s['user_id'] == userId).toList();
            final userAchievementCount = userAchievements.where((ua) => ua['user_id'] == userId).length;
            
            return {
              'user_id': userId,
              'username': user['username'],
              'coins': user['coins'],
              'total_tasks': userTaskCount,
              'completed_tasks': userCompletedTasks,
              'completion_rate': userTaskCount > 0 ? (userCompletedTasks / userTaskCount * 100).toStringAsFixed(1) + '%' : '0%',
              'total_plans': userPlans,
              'current_streak': userStatsRecord.isNotEmpty ? userStatsRecord.first['current_streak'] : 0,
              'achievements_unlocked': userAchievementCount,
            };
          }).toList(),
          
          // ACHIEVEMENT ANALİZİ
          'achievement_analysis': achievements.map((achievement) {
            final achievementId = achievement['id'];
            final unlockedCount = userAchievements.where((ua) => ua['achievement_id'] == achievementId).length;
            
            return {
              'achievement_id': achievementId,
              'title': achievement['title'],
              'description': achievement['description'],
              'unlocked_by_users': unlockedCount,
              'unlock_percentage': users.isNotEmpty ? (unlockedCount / users.length * 100).toStringAsFixed(1) + '%' : '0%',
            };
          }).toList(),
        }
      };
      
      final jsonString = JsonEncoder.withIndent('  ').convert(databaseSnapshot);
      
      // Console'a yazdır
      print('📄 ===== DATABASE JSON START =====');
      print(jsonString);
      print('📄 ===== DATABASE JSON END =====');
      
      // Clipboard'a kopyala
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      // Dosyaya kaydet
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/database_snapshot_v9.json');
      await file.writeAsString(jsonString);      
    } catch (e) {
      print('JSON export hatası: $e');
      rethrow;
    }
  }
  /* DATABASE FONKSIYONLARI SONU */


  /* KULLANICI İŞLEMLERİ FONKSİYONLARI BAŞLANGICI */
  Future<int> registerUser(User user) async {
    final db = await instance.database;

    // Kullanıcı adı ya da e-posta zaten var mı kontrol et
    var result = await db.rawQuery('''
      SELECT * FROM users WHERE username = ? OR email = ?
    ''', [user.username, user.email]);

    if (result.isNotEmpty) {
      // Eğer kullanıcı adı ya da e-posta zaten varsa, -1 döndür
      return -1;
    }

    // Bu satır hem kaydı ekler, hem de yeni ID'yi döndürür
    final newUserId = await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print(" Yeni kullanıcı kaydedildi! ID: $newUserId");
    
    return newUserId;  // Kullanıcı ID'sini döndür
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await instance.database;
    final hash = sha256.convert(utf8.encode(password)).toString();

    try {
      final result = await db.rawQuery(
        'SELECT * FROM users WHERE email = ? AND password_hash = ?',
        [email, password],
      );

      if (result.isNotEmpty) {
        print("Kullanıcı bulundu: ${result.first}");
        return User.fromMap(result.first);
      } else {
        print("Kullanıcı bulunamadı: $email, $hash");
        return null;
      }
    } catch (e) {
      print("Hata: $e");
      return null;
    }
  }

  Future<void> giveAllBodiesToNewUser(int userId) async {
    final db = await instance.database;
      // Bu fonksiyon yeni oluşturulan kullanıcıya tüm body'lerin hediye edilmesini sağlar.
    try {    
      final bodyCategory = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: ['body'],
        limit: 1,
      );
      
      final bodyCategoryId = bodyCategory.first['id'] as int;
      
      final bodyItems = await db.query(
        'shop_items',
        where: 'category_id = ?',
        whereArgs: [bodyCategoryId],
      );
          
      for (var item in bodyItems) {
        await db.insert('user_items', {
          'user_id': userId,
          'item_id': item['id'],
          'purchased_at': DateTime.now().toIso8601String(),
        });        
      }
      
      final firstBody = bodyItems.where((item) => item['name'] == 'body1').firstOrNull;
      if (firstBody != null) {
        await db.insert('user_selected_items', {
          'user_id': userId,
          'item_id': firstBody['id'],
        });
      }
    } catch (e) {
      print("Body hediye etme hatası: $e");
      throw e;
    }
  }
  /* KULLANICI İŞLEMLERİ FONKSİYONLARI SONU */


  /* GÖREV SİSTEMİ FONKSİYONLARI BAŞLANGICI */
  Future<void> generateDailyTasks() async {
    // Daily template'den daily task oluşturma fonksiyonu yani belirli günlerde tekrar eden görevler (Tüm kullanıcılar için)
    final db = await database;
    final today = DateTime.now();
    final dayOfWeek = today.weekday - 1; // 0=Pazartesi, 6=Pazar
    final todayString = today.toIso8601String().split('T')[0];
    
    print('Daily task oluşturma başlatıldı - Gün: $dayOfWeek, Tarih: $todayString');
    
    // Tüm aktif daily template'leri al
    final dailyTemplates = await db.query(
      'daily_templates',
      where: 'is_active = 1',
    );
        
    for (var template in dailyTemplates) {
      String selectedDays = template['selected_days'] as String;
      List<String> days = selectedDays.split(',');
      
      // Bugün bu daily çalışacak mı kontrolü
      if (dayOfWeek < days.length && days[dayOfWeek] == '1') {
        // Bugün için bu daily zaten oluşturulmuş mu kontrolü
        final existingTask = await db.query(
          'tasks',
          where: 'daily_template_id = ? AND DATE(created_at) = ?',
          whereArgs: [template['id'], todayString],
        );
        
        if (existingTask.isEmpty) {
          await db.insert('tasks', {
            'user_id': template['user_id'],
            'title': template['title'],
            'description': template['description'],
            'type': 'daily',
            'is_active': '1',
            'coin_reward': template['coin_reward'],
            'daily_template_id': template['id'],
          });
          
          print('Daily task oluşturuldu: ${template['title']} (User: ${template['user_id']})');
        } else {
          print('Daily task zaten var: ${template['title']}');
        }
      }
    }
  }

  Future<void> generateDailyTasksForUser(int userId) async {
    // Daily template'den daily task oluşturma fonksiyonu yani belirli günlerde tekrar eden görevler (Belirli kullanıcı bazında)
    final db = await database;
    final today = DateTime.now();
    final dayOfWeek = today.weekday - 1; // 0=Pazartesi, 6=Pazar
    final todayString = today.toIso8601String().split('T')[0]; // 2025-06-09
    
    print('Kullanıcı $userId için daily task kontrolü başlatıldı - Gün: $dayOfWeek');
    
    // Bu kullanıcının aktif daily template'lerini al
    final dailyTemplates = await db.query(
      'daily_templates',
      where: 'user_id = ? AND is_active = 1',
      whereArgs: [userId],
    );
    
    print('📋 Kullanıcı $userId için ${dailyTemplates.length} aktif daily template bulundu');
    
    for (var template in dailyTemplates) {
      String selectedDays = template['selected_days'] as String;
      List<String> days = selectedDays.split(',');
      
      // Bugün bu daily çalışacak mı?
      if (dayOfWeek < days.length && days[dayOfWeek] == '1') {
        // Bugün için bu daily zaten oluşturulmuş mu?
        String? lastGenerated = template['last_generated_date'] as String?;

        if (lastGenerated != todayString) {
          // Bugün için bu daily henüz oluşturulmamış İSE
          
          // Daily task'ı oluştur
          await db.insert('tasks', {
            'user_id': template['user_id'],
            'title': template['title'],
            'description': template['description'],
            'type': 'daily',
            'is_active': '1',
            'coin_reward': template['coin_reward'],
            'daily_template_id': template['id'],
            'is_completed': 0,
          });
          
          // Daily template'in last_generated_date'ini güncelle
          await db.update(
            'daily_templates',
            {'last_generated_date': todayString},
            where: 'id = ?',
            whereArgs: [template['id']],
          );
          
          print('Daily task oluşturuldu: ${template['title']}');
        } else {
          print('Daily task zaten var: ${template['title']}');
        }
      } else {
        print('Bugün çalışmayan daily: ${template['title']}');
      }
    }
  }

  Future<void> deleteDailyTemplate(int templateId) async {
    // Bir daily template silindiğinde ona bağlı tamamlanmamış daily task'ı da silinir.
    final db = await database;
    
    try {
      await db.transaction((txn) async {
        // 1. Bu template'den oluşturulan yalnızca tamamlanmamış todo'ları sil
        await txn.delete(
          'tasks',
          where: 'daily_template_id = ? AND is_completed = 0',           
          whereArgs: [templateId],
        );
        
        // 2. Daily template'i sil
        await txn.delete(
          'daily_templates',
          where: 'id = ?',
          whereArgs: [templateId],
        );
      });
      
      print('Daily template ve ilgili tamamlanmamış task\'lar silindi: $templateId');
    } catch (e) {
      print('Daily template silme hatası: $e');
      throw e;
    }
  }

  Future<void> deactivateTodayTaskForDaily(int dailyTemplateId, DateTime today) async {
    // Daily edit edilince bugünkü task'ı deaktif et
    final db = await database;
    
    try {
      // Bugünün tarih string'ini oluştur (YYYY-MM-DD formatında)
      final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      
      // Bu daily'den bugün oluşturulan ve henüz tamamlanmamış task'ı bul ve deaktif et
      final result = await db.update(
        'tasks',
        {'is_active': 0}, // 🎯 Task'ı deaktif et
        where: '''
          daily_template_id = ? 
          AND DATE(created_at) = ? 
          AND is_completed = 0
        ''',
        whereArgs: [dailyTemplateId, todayStr],
      );
      
      if (result > 0) {
        print('Bugünkü tamamlanmamış task deaktif edildi: $dailyTemplateId');
      } else {
        print('Deaktif edilecek task bulunamadı (zaten tamamlanmış olabilir)');
      }
    } catch (e) {
      print('Task deaktif etme hatası: $e');
      throw e;
    }
  }

  Future<Map<String, dynamic>> toggleTaskCompletion(int taskId, int userId, bool isCompleted) async {
    // Görev tamamlama durumunu değiştirip coin işlemlerini gerçekleştirir.
    final db = await database;
    
    try {
      return await db.transaction((txn) async {
        Map<String, dynamic> result = {
          'success': false,
          'coinReward': 0,
          'newCoinTotal': 0,
          'streakCount': 0,
          'completionRate': 0.0,
          // KALDIRILDI: 'achievements': <String>[],
        };
        
        if (isCompleted) {
          // task tamamlandı
          await txn.update(
            'tasks',
            {'is_completed': 1},
            where: 'id = ?',
            whereArgs: [taskId],
          );
          
          // Task completion kaydı eklendi
          await txn.insert('task_completion', {
            'task_id': taskId,
          });
          
          // Task bilgilerini al ve coin ver
          final task = await txn.query('tasks', where: 'id = ?', whereArgs: [taskId]);
          if (task.isNotEmpty) {
            int coinReward = task.first['coin_reward'] as int;
            
            final user = await txn.query('users', where: 'id = ?', whereArgs: [userId]);
            if (user.isNotEmpty) {
              int currentCoins = user.first['coins'] as int;
              int newCoinTotal = currentCoins + coinReward;
              
              await txn.update(
                'users',
                {'coins': newCoinTotal},
                where: 'id = ?',
                whereArgs: [userId],
              );
              
              result['coinReward'] = coinReward;
              result['newCoinTotal'] = newCoinTotal;
            }
          }
          
          
        } else {
          // task tamamlanması geri alındı
          String today = DateTime.now().toIso8601String().split('T')[0];
          
          await txn.delete(
            'task_completion',
            where: 'task_id = ? AND DATE(completed_at) = ?',
            whereArgs: [taskId, today],
          );
          
          await txn.update(
            'tasks',
            {'is_completed': 0},
            where: 'id = ?',
            whereArgs: [taskId],
          );
          
          // task ile verilmiş olan coin geri alındı.
          final task = await txn.query('tasks', where: 'id = ?', whereArgs: [taskId]);
          if (task.isNotEmpty) {
            int coinReward = task.first['coin_reward'] as int;
            
            final user = await txn.query('users', where: 'id = ?', whereArgs: [userId]);
            if (user.isNotEmpty) {
              int currentCoins = user.first['coins'] as int;
              int newCoinTotal = Math.max(0, currentCoins - coinReward);
              
              await txn.update(
                'users',
                {'coins': newCoinTotal},
                where: 'id = ?',
                whereArgs: [userId],
              );
              
              result['coinReward'] = -coinReward;
              result['newCoinTotal'] = newCoinTotal;
            }
          }
        }
        
        // istatistikler güncellendi
        String today = DateTime.now().toIso8601String().split('T')[0];
        await _updateDailyStatsInternal(txn, userId, today);
        
        // İstatistikler resulta eklendi
        final todayStats = await txn.query(
          'user_stats',
          where: 'user_id = ? AND date = ?',
          whereArgs: [userId, today],
        );
        
        if (todayStats.isNotEmpty) {
          result['streakCount'] = todayStats.first['streak_count'] as int;
          result['completionRate'] = (todayStats.first['completion_rate'] as num).toDouble();
        }
                
        result['success'] = true;
        return result;
      });
    } catch (e) {
      print('Task toggle hatası: $e');
      return {
        'success': false,
        'error': e.toString(),
        'coinReward': 0,
        'newCoinTotal': 0,
        'streakCount': 0,
        'completionRate': 0.0,
      };
    }
  }
  /* GÖREV SİSTEMİ FONKSİYONLARI SONU */
  

  /* İSTATİSTİK SİSTEMİ FONKSİYONLARI BAŞLANGICI */
  Future<void> _updateDailyStatsInternal(DatabaseExecutor txn, int userId, String date) async {
    // Günlük istatistikleri günceller (tamamlanan görev sayısı, başarı oranı, vs.)
    try {
      // O günün görevlerini hesapla
      final totalTasks = await txn.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE user_id = ? AND DATE(created_at) = ? AND is_active = 1
      ''', [userId, date]);
      
      final completedTasks = await txn.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE user_id = ? AND DATE(created_at) = ? AND is_completed = 1 AND is_active = 1
      ''', [userId, date]);
      
      final dailyTasks = await txn.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE user_id = ? AND DATE(created_at) = ? AND type = 'daily' AND is_active = 1
      ''', [userId, date]);
      
      final onetimeTasks = await txn.rawQuery('''
        SELECT COUNT(*) as count FROM tasks 
        WHERE user_id = ? AND DATE(created_at) = ? AND type = 'one_time' AND is_active = 1
      ''', [userId, date]);
      
      final coinsEarned = await txn.rawQuery('''
        SELECT COALESCE(SUM(coin_reward), 0) as total FROM tasks 
        WHERE user_id = ? AND DATE(created_at) = ? AND is_completed = 1 AND is_active = 1
      ''', [userId, date]);
      
      int total = (totalTasks.first['count'] as int?) ?? 0;
      int completed = (completedTasks.first['count'] as int?) ?? 0;
      int daily = (dailyTasks.first['count'] as int?) ?? 0;
      int onetime = (onetimeTasks.first['count'] as int?) ?? 0;
      int coins = (coinsEarned.first['total'] as int?) ?? 0;
      
      double completionRate = total > 0 ? (completed / total) : 0.0;
      
      // Streak hesapla
      int streakCount = await _calculateCurrentStreakInternal(txn, userId, date);
      
      await txn.insert(
        'user_stats',
        {
          'user_id': userId,
          'date': date,
          'total_tasks': total,
          'completed_tasks': completed,
          'completion_rate': completionRate,
          'daily_tasks': daily,
          'onetime_tasks': onetime,
          'streak_count': streakCount,
          'coins_earned': coins,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
    } catch (e) {
      print('İç istatistik güncelleme hatası: $e');
    }
  }

  Future<int> _calculateCurrentStreakInternal(DatabaseExecutor txn, int userId, String currentDate) async {
    // Ardışık başarılı gün sayısını yani STREAK değerini hesaplar
    try {
      final stats = await txn.query(
        'user_stats',
        where: 'user_id = ? AND date <= ?',
        whereArgs: [userId, currentDate],
        orderBy: 'date DESC',
        limit: 30,
      );
      
      int streak = 0;
      DateTime checkDate = DateTime.parse(currentDate);
      
      for (var stat in stats) {
        String statDate = stat['date'] as String;
        double completionRate = (stat['completion_rate'] as num).toDouble();
        
        if (completionRate >= 0.3) { // %30 üzeri başarılı
          streak++;
          checkDate = checkDate.subtract(Duration(days: 1));
        } else {
          break;
        }
      }
      
      return streak;
      
    } catch (e) {
      print('İç streak hesaplama hatası: $e');
      return 0;
    }
  }

  Future<Map<String, dynamic>> getWeeklyStats(int userId) async {
    // Haftalık istatistik bilgilerini getirir
    final db = await database;
    
    final weeklyStats = await db.rawQuery('''
      SELECT 
        SUM(total_tasks) as total_tasks,
        SUM(completed_tasks) as completed_tasks,
        AVG(completion_rate) as avg_completion_rate,
        SUM(daily_tasks) as daily_tasks,
        SUM(onetime_tasks) as onetime_tasks,
        MAX(streak_count) as max_streak,
        SUM(coins_earned) as total_coins
      FROM user_stats 
      WHERE user_id = ? AND date >= date('now', '-7 days')
    ''', [userId]);
    
    final result = weeklyStats.first;
    
    return {
      'total_tasks': result['total_tasks'] ?? 0,
      'completed_tasks': result['completed_tasks'] ?? 0,
      'completion_rate': result['avg_completion_rate'] ?? 0.0,
      'daily_tasks': result['daily_tasks'] ?? 0,
      'onetime_tasks': result['onetime_tasks'] ?? 0,
      'max_streak': result['max_streak'] ?? 0,
      'total_coins': result['total_coins'] ?? 0,
    };
  }

  Future<Map<String, dynamic>> getMonthlyStats(int userId) async {
    // Aylıkistatistik bilgilerini getirir
    final db = await database;
    
    final monthlyStats = await db.rawQuery('''
      SELECT 
        SUM(total_tasks) as total_tasks,
        SUM(completed_tasks) as completed_tasks,
        AVG(completion_rate) as avg_completion_rate,
        SUM(daily_tasks) as daily_tasks,
        SUM(onetime_tasks) as onetime_tasks,
        MAX(streak_count) as max_streak,
        SUM(coins_earned) as total_coins,
        COUNT(DISTINCT date) as active_days
      FROM user_stats 
      WHERE user_id = ? AND date >= date('now', '-30 days')
    ''', [userId]);
    
    final result = monthlyStats.first;
    
    return {
      'total_tasks': result['total_tasks'] ?? 0,
      'completed_tasks': result['completed_tasks'] ?? 0,
      'completion_rate': result['avg_completion_rate'] ?? 0.0,
      'daily_tasks': result['daily_tasks'] ?? 0,
      'onetime_tasks': result['onetime_tasks'] ?? 0,
      'max_streak': result['max_streak'] ?? 0,
      'total_coins': result['total_coins'] ?? 0,
      'active_days': result['active_days'] ?? 0,
    };
  }
  
  Future<Map<String, dynamic>> getTodayTaskStats(int userId) async {
    // Bugünkü görev istatistikleri
    final db = await database;
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_tasks,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_tasks,
        SUM(CASE WHEN type = 'daily' THEN 1 ELSE 0 END) as daily_tasks,
        SUM(CASE WHEN type = 'one_time' THEN 1 ELSE 0 END) as onetime_tasks,
        SUM(CASE WHEN type = 'daily' AND is_completed = 1 THEN 1 ELSE 0 END) as completed_dailies,
        SUM(CASE WHEN type = 'one_time' AND is_completed = 1 THEN 1 ELSE 0 END) as completed_onetimes,
        SUM(CASE WHEN is_completed = 1 THEN coin_reward ELSE 0 END) as coins_earned
      FROM tasks 
      WHERE user_id = ? AND DATE(created_at) = ? AND is_active = 1
    ''', [userId, today]);
    
    final data = result.first;
    final total = data['total_tasks'] as int;
    final completed = data['completed_tasks'] as int;
    final completionRate = total > 0 ? (completed / total * 100) : 0.0;
    
    return {
      'total_tasks': total,
      'completed_tasks': completed,
      'completion_rate': completionRate,
      'daily_tasks': data['daily_tasks'] as int,
      'onetime_tasks': data['onetime_tasks'] as int,
      'completed_dailies': data['completed_dailies'] as int,
      'completed_onetimes': data['completed_onetimes'] as int,
      'coins_earned': data['coins_earned'] as int,
      'performance_emoji': _getPerformanceEmoji(completionRate),
      'performance_color': _getPerformanceColor(completionRate),
      'performance_text': _getPerformanceText(completionRate),
    };
  }

  Future<Map<String, dynamic>> getDailyTaskAnalytics(int userId, int dailyTemplateId) async {
    // Daily görev analitikleri
    final db = await database;
    
    // Son 30 gün içindeki bu daily'nin performansı
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_generated,
        SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed_count,
        AVG(CASE WHEN is_completed = 1 THEN 1.0 ELSE 0.0 END) * 100 as completion_rate,
        MAX(DATE(created_at)) as last_completed_date
      FROM tasks 
      WHERE user_id = ? AND daily_template_id = ? 
      AND DATE(created_at) >= date('now', '-30 days')
    ''', [userId, dailyTemplateId]);
    
    final data = result.first;
    final completionRate = (data['completion_rate'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'total_generated': data['total_generated'] as int,
      'completed_count': data['completed_count'] as int,
      'completion_rate': completionRate,
      'last_completed_date': data['last_completed_date'],
      'performance_grade': _getGradeFromRate(completionRate),
    };
  }

  Future<Map<String, dynamic>> getWeeklyComparison(int userId) async {
    try {
      // Haftalık karşılaştırma
      final db = await database;
      final now = DateTime.now();
      final thisWeekStart = now.subtract(Duration(days: now.weekday - 1));
      final lastWeekStart = thisWeekStart.subtract(Duration(days: 7));
      
      final thisWeekEnd = thisWeekStart.add(Duration(days: 6));
      final lastWeekEnd = lastWeekStart.add(Duration(days: 6));
      
      // Bu hafta
      final thisWeek = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(total_tasks), 0) as total_tasks,
          COALESCE(SUM(completed_tasks), 0) as completed_tasks,
          COALESCE(SUM(coins_earned), 0) as coins_earned,
          COALESCE(AVG(completion_rate), 0) as avg_completion_rate,
          COALESCE(MAX(streak_count), 0) as max_streak
        FROM user_stats 
        WHERE user_id = ? AND date BETWEEN ? AND ?
      ''', [userId, thisWeekStart.toIso8601String().split('T')[0], thisWeekEnd.toIso8601String().split('T')[0]]);
      
      // Geçen hafta
      final lastWeek = await db.rawQuery('''
        SELECT 
          COALESCE(SUM(total_tasks), 0) as total_tasks,
          COALESCE(SUM(completed_tasks), 0) as completed_tasks,
          COALESCE(SUM(coins_earned), 0) as coins_earned,
          COALESCE(AVG(completion_rate), 0) as avg_completion_rate,
          COALESCE(MAX(streak_count), 0) as max_streak
        FROM user_stats 
        WHERE user_id = ? AND date BETWEEN ? AND ?
      ''', [userId, lastWeekStart.toIso8601String().split('T')[0], lastWeekEnd.toIso8601String().split('T')[0]]);
      
      final thisWeekData = thisWeek.first;
      final lastWeekData = lastWeek.first;
      
      return {
        'this_week': {
          'total_tasks': _safeInt(thisWeekData['total_tasks']),
          'completed_tasks': _safeInt(thisWeekData['completed_tasks']),
          'coins_earned': _safeInt(thisWeekData['coins_earned']),
          'avg_completion_rate': _safeDouble(thisWeekData['avg_completion_rate']),
          'max_streak': _safeInt(thisWeekData['max_streak']),
        },
        'last_week': {
          'total_tasks': _safeInt(lastWeekData['total_tasks']),
          'completed_tasks': _safeInt(lastWeekData['completed_tasks']),
          'coins_earned': _safeInt(lastWeekData['coins_earned']),
          'avg_completion_rate': _safeDouble(lastWeekData['avg_completion_rate']),
          'max_streak': _safeInt(lastWeekData['max_streak']),
        },
        'improvements': _calculateImprovements(thisWeekData, lastWeekData),
      };
    } catch (e) {
      print('❌ getWeeklyComparison hatası: $e');
      return {
        'this_week': {
          'total_tasks': 0,
          'completed_tasks': 0,
          'coins_earned': 0,
          'avg_completion_rate': 0.0,
          'max_streak': 0,
        },
        'last_week': {
          'total_tasks': 0,
          'completed_tasks': 0,
          'coins_earned': 0,
          'avg_completion_rate': 0.0,
          'max_streak': 0,
        },
        'improvements': {
          'task_change': 0,
          'completion_change': 0,
          'coin_change': 0,
          'rate_change': 0.0,
          'is_improving': false,
        },
      };
    }
  }

  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> _calculateImprovements(Map<String, dynamic> thisWeek, Map<String, dynamic> lastWeek) {
    final thisWeekTasks = _safeInt(thisWeek['total_tasks']);
    final lastWeekTasks = _safeInt(lastWeek['total_tasks']);
    
    final thisWeekCompleted = _safeInt(thisWeek['completed_tasks']);
    final lastWeekCompleted = _safeInt(lastWeek['completed_tasks']);
    
    final thisWeekCoins = _safeInt(thisWeek['coins_earned']);
    final lastWeekCoins = _safeInt(lastWeek['coins_earned']);
    
    final thisWeekRate = _safeDouble(thisWeek['avg_completion_rate']);
    final lastWeekRate = _safeDouble(lastWeek['avg_completion_rate']);
    
    final taskChange = thisWeekTasks - lastWeekTasks;
    final completionChange = thisWeekCompleted - lastWeekCompleted;
    final coinChange = thisWeekCoins - lastWeekCoins;
    final rateChange = thisWeekRate - lastWeekRate; 
    
    final isImproving = (completionChange >= 0 && coinChange >= 0 && rateChange >= 0);
    
    return {
      'task_change': taskChange,
      'completion_change': completionChange,
      'coin_change': coinChange,
      'rate_change': rateChange,
      'is_improving': isImproving,
    };
  }

  Future<List<Map<String, dynamic>>> getMostCompletedTasks(int userId, {int limit = 5}) async {
    // En çok yapılan görevler
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        title,
        type,
        COUNT(*) as completion_count,
        SUM(coin_reward) as total_coins_earned
      FROM tasks 
      WHERE user_id = ? AND is_completed = 1 
      AND DATE(created_at) >= date('now', '-30 days')
      GROUP BY title, type
      ORDER BY completion_count DESC
      LIMIT ?
    ''', [userId, limit]);
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getLeastCompletedDailies(int userId, {int limit = 3}) async {
    // En ihmal edilen daily'ler
    final db = await database;
    
    final result = await db.rawQuery('''
      SELECT 
        dt.title,
        dt.id as template_id,
        COUNT(t.id) as generated_count,
        SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) as completed_count,
        (SUM(CASE WHEN t.is_completed = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(t.id)) as completion_rate
      FROM daily_templates dt
      LEFT JOIN tasks t ON dt.id = t.daily_template_id 
      WHERE dt.user_id = ? AND dt.is_active = 1
      AND t.created_at >= date('now', '-30 days')
      GROUP BY dt.id, dt.title
      HAVING generated_count > 0
      ORDER BY completion_rate ASC
      LIMIT ?
    ''', [userId, limit]);
    
    return result;
  }

  Future<Map<String, dynamic>> getWeeklySummary(int userId, DateTime weekStart) async {
    // Haftalık özet
    final db = await database;
    final weekEnd = weekStart.add(Duration(days: 6));
    
    final summary = await db.rawQuery('''
      SELECT 
        SUM(total_tasks) as total_tasks,
        SUM(completed_tasks) as completed_tasks,
        SUM(coins_earned) as total_coins,
        AVG(completion_rate) as avg_completion_rate,
        MAX(streak_count) as best_streak,
        COUNT(DISTINCT date) as active_days
      FROM user_stats 
      WHERE user_id = ? AND date BETWEEN ? AND ?
    ''', [userId, weekStart.toIso8601String().split('T')[0], weekEnd.toIso8601String().split('T')[0]]);
    
    final data = summary.first;
    final completionRate = (data['avg_completion_rate'] as num?)?.toDouble() ?? 0.0;
    
    return {
      'week_start': weekStart.toIso8601String().split('T')[0],
      'week_end': weekEnd.toIso8601String().split('T')[0],
      'total_tasks': data['total_tasks'] as int,
      'completed_tasks': data['completed_tasks'] as int,
      'total_coins': data['total_coins'] as int,
      'avg_completion_rate': completionRate,
      'best_streak': data['best_streak'] as int,
      'active_days': data['active_days'] as int,
      'weekly_grade': _getGradeFromRate(completionRate),
      'personality_type': getPersonalityType(completionRate),
    };
  }

  String _getPerformanceEmoji(double rate) {
    // Yardımcı fonksiyonlar
    if (rate >= 86) return '🔥';
    if (rate >= 71) return '😍';
    if (rate >= 51) return '😊';
    if (rate >= 31) return '😐';
    return '😴';
  }

  Color _getPerformanceColor(double rate) {
    if (rate >= 86) return Colors.green;
    if (rate >= 71) return Colors.lightGreen;
    if (rate >= 51) return Colors.yellow;
    if (rate >= 31) return Colors.orange;
    return Colors.red;
  }

  String _getPerformanceText(double rate) {
    if (rate >= 86) return 'Efsane';
    if (rate >= 71) return 'Harika';
    if (rate >= 51) return 'İyi';
    if (rate >= 31) return 'Orta';
    return 'Uyuşuk';
  }

  String _getGradeFromRate(double rate) {
    if (rate >= 90) return 'A+';
    if (rate >= 85) return 'A';
    if (rate >= 80) return 'A-';
    if (rate >= 75) return 'B+';
    if (rate >= 70) return 'B';
    if (rate >= 65) return 'B-';
    if (rate >= 60) return 'C+';
    if (rate >= 55) return 'C';
    if (rate >= 50) return 'C-';
    return 'D';
  }

  String getPersonalityType(double completionRate) {
    if (completionRate >= 90) return '🏆 Görev Makinesi';
    if (completionRate >= 80) return '⚡ Süper Verimli';
    if (completionRate >= 70) return '🎯 Hedef Odaklı';
    if (completionRate >= 60) return '📈 Gelişen Kahraman';
    if (completionRate >= 50) return '🌱 Büyüyen Tohum';
    return '💪 Potansiyel Dolu';
  }

  String getMotivationalQuote(DateTime date, double performance) {
    // Motivasyonel söz getirme
    final quotes = _getQuotesByCategory(performance);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final index = dayOfYear % quotes.length;
    return quotes[index];
  }

  List<String> _getQuotesByCategory(double performance) {
    if (performance >= 80) {
      return [
        "Harika gidiyorsun! Başarı senin için bir alışkanlık olmuş! 🔥",
        "Sen gerçek bir şampiyon gibi davranıyorsun! 🏆",
        "Bu performans ile sınırların yok! ⚡",
        "Mükemmellik senin doğan! Böyle devam! 🌟",
      ];
    } else if (performance >= 60) {
      return [
        "İyi bir tempoda ilerliyorsun! 💪",
        "Kararlılığın seni başarıya götürüyor! 🎯",
        "Her gün biraz daha güçleniyorsun! 📈",
        "Hedeflerine odaklanmış bir şekilde ilerliyorsun! 🚀",
      ];
    } else if (performance >= 40) {
      return [
        "Başlangıç her zaman zordur, ama sen yapabilirsin! 🌱",
        "Küçük adımlar büyük değişimlere yol açar! 👣",
        "Bugün dünden daha iyi olman yeterli! 📊",
        "Gelişim sürecinde olman harika! 🌿",
      ];
    } else {
      return [
        "Her büyük yolculuk tek bir adımla başlar! 🚶‍♂️",
        "Potansiyelin sonsuz, sadece harekete geç! 💎",
        "Başarısızlık değil, öğrenme fırsatı! 📚",
        "Yarın yeni bir gün, yeni bir şans! 🌅",
      ];
    }
  }
  /* İSTATİSTİK SİSTEMİ FONKSİYONLARI SONU */

  /* BAŞARIM SİSTEMİ FONKSİYONLARI BAŞLANGICI */
  Future<void> insertInitialAchievements() async {
    // Başlangıç başarımlarını ekler
    final db = await database;
    
    final achievements = [
      {
        'title': 'İlk Adım',
        'description': 'İlk görevini tamamla',
        'condition_type': 'total_completed',
        'condition_value': 1,
        'coin_reward': 10,
      },
      {
        'title': 'Başlangıç',
        'description': '5 görev tamamla',
        'condition_type': 'total_completed',
        'condition_value': 5,
        'coin_reward': 25,
      },
      {
        'title': 'Kararlı',
        'description': '3 gün üst üste görev tamamla',
        'condition_type': 'streak',
        'condition_value': 3,
        'coin_reward': 50,
      },
      {
        'title': 'Azimli',
        'description': '7 gün üst üste görev tamamla',
        'condition_type': 'streak',
        'condition_value': 7,
        'coin_reward': 100,
      },
      {
        'title': 'Süper Kahraman',
        'description': '30 gün üst üste görev tamamla',
        'condition_type': 'streak',
        'condition_value': 30,
        'coin_reward': 500,
      },
    ];
    
    for (final achievement in achievements) {
      await db.insert('achievements', achievement, 
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }    
  }

  Future<void> checkAndUnlockAchievements(int userId) async {
    // Kullanıcının başarımlarını kontrol eder ve yeni başarımları açar
    final db = await database;
    
    // Kullanıcının mevcut istatistiklerini al
    final userStats = await db.rawQuery('''
      SELECT 
        SUM(completed_tasks) as total_completed,
        MAX(streak_count) as max_streak
      FROM user_stats WHERE user_id = ?
    ''', [userId]);
    
    if (userStats.isEmpty) return;
    
    final totalCompleted = userStats.first['total_completed'] as int? ?? 0;
    final maxStreak = userStats.first['max_streak'] as int? ?? 0;
    
    // Henüz kazanılmamış başarımları al
    final availableAchievements = await db.rawQuery('''
      SELECT * FROM achievements 
      WHERE id NOT IN (
        SELECT achievement_id FROM user_achievements WHERE user_id = ?
      )
    ''', [userId]);
    
    // Her başarım için kontrol yap
    for (final achievement in availableAchievements) {
      final conditionType = achievement['condition_type'] as String;
      final conditionValue = achievement['condition_value'] as int;
      bool unlocked = false;
      
      switch (conditionType) {
        case 'total_completed':
          unlocked = totalCompleted >= conditionValue;
          break;
        case 'streak':
          unlocked = maxStreak >= conditionValue;
          break;
      }
      
      if (unlocked) {
        // Başarımı kullanıcıya ver
        await db.insert('user_achievements', {
          'user_id': userId,
          'achievement_id': achievement['id'],
        });
        
        // Coin ödülünü ver
        final coinReward = achievement['coin_reward'] as int;
        await db.execute('''
          UPDATE users SET coins = coins + ? WHERE id = ?
        ''', [coinReward, userId]);
        
        print('🏆 Başarım kazanıldı: ${achievement['title']} (+$coinReward coin)');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getUserAchievements(int userId) async {
    // Kullanıcının kazanmış olduğu başarımları getirir
    final db = await database;
    
    final achievements = await db.rawQuery('''
      SELECT 
        a.title,
        a.description,
        a.icon,
        a.coin_reward,
        ua.earned_at
      FROM user_achievements ua
      JOIN achievements a ON ua.achievement_id = a.id
      WHERE ua.user_id = ?
      ORDER BY ua.earned_at DESC
    ''', [userId]);
    
    return achievements;
  }

  Future<List<Map<String, dynamic>>> getAllAchievementsWithStatus(int userId) async {
    // Kazanılmış veya kazanılmamış tüm başarımları getirir.
    final db = await database;
    
    final achievements = await db.rawQuery('''
      SELECT 
        a.id,
        a.title,
        a.description,
        a.icon,
        a.condition_type,
        a.condition_value,
        a.coin_reward,
        CASE WHEN ua.user_id IS NOT NULL THEN 1 ELSE 0 END as is_unlocked,
        ua.earned_at
      FROM achievements a
      LEFT JOIN user_achievements ua ON a.id = ua.achievement_id AND ua.user_id = ?
      ORDER BY is_unlocked DESC, a.coin_reward ASC
    ''', [userId]);
    
    return achievements;
  }
  /* BAŞARIM SİSTEMİ FONKSİYONLARI SONU */

  Future<int> getTotalIncompleteTaskCount(int userId) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM tasks
      WHERE user_id = ? AND is_completed = 0
    ''', [userId]);

    final count = Sqflite.firstIntValue(result);
    print("eleman sayisi: ");
    print(count);
    return count ?? 0;
  }
}