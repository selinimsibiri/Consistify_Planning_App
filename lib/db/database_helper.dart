import 'dart:io';

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

  Future<Database> get database async {
      print(_database);

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

   // Users tablosunun kolonlarını listeleyen fonksiyon
  Future<List<String>> getUsersTableColumns() async {
    final db = await instance.database;
    final result = await db.rawQuery('PRAGMA table_info(users);'); // SQLite PRAGMA komutu ile tablo bilgisi alıyoruz

    List<String> columns = [];
    for (var column in result) {
      // Değeri String'e dönüştür
      columns.add(column['name'] as String); // 'name' alanını String olarak alıyoruz
    }
    return columns;
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
        last_generated_date TEXT,re
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
      
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

    
    
    await insertInitialData(db);
  }

  Future close() async {
    final db = await instance.database;
    _database = null;
    db.close();
  }

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
    
    print("🎯 Yeni kullanıcı kaydedildi! Gerçek ID: $newUserId");
    
    return newUserId;  // ✅ Gerçek kullanıcı ID'sini döndür
  }


  Future<User?> loginUser(String email, String password) async {
    final db = await instance.database;

    // Hash'i hesapla
    final hash = sha256.convert(utf8.encode(password)).toString();

    print("Sorgulanan email: $email, hash: $hash"); // Debugging

    try {
      // rawQuery ile SQL sorgusunu yazıyoruz
      final result = await db.rawQuery(
        'SELECT * FROM users WHERE email = ? AND password_hash = ?',
        [email, password],
      );

      // Eğer sorgu hatasızsa ve veri varsa
      if (result.isNotEmpty) {
        print("Kullanıcı bulundu: ${result.first}"); // Debugging
        return User.fromMap(result.first);
      } else {
        print("❌ Kullanıcı bulunamadı: $email, $hash"); // Debugging: Kayıt bulunamadı
        return null;
      }
    } catch (e) {
      print("Hata: $e"); // Hata mesajı
      return null;
    }
  }

  Future<void> insertInitialData(Database db) async {
      // Check if categories table is already filled
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

    // Insert Shop Items - BODY (category_id: 1)
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
    // BOTTOM (category_id: 6)
    await db.insert('shop_items', {'name': 'bottom1', 'category_id': 6, 'price': 5});
    await db.insert('shop_items', {'name': 'bottom2', 'category_id': 6, 'price': 5});
    await db.insert('shop_items', {'name': 'bottom3', 'category_id': 6, 'price': 5});

    // TOPS (category_id: 5)
    await db.insert('shop_items', {'name': 'top1', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top2', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top3', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top4', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top5', 'category_id': 5, 'price': 5});
    await db.insert('shop_items', {'name': 'top6', 'category_id': 5, 'price': 5});
    
    // SHOES (category_id: 7)
    await db.insert('shop_items', {'name': 'shoes1', 'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes2',   'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes3', 'category_id': 7, 'price': 5});
    await db.insert('shop_items', {'name': 'shoes4', 'category_id': 7, 'price': 5});


    print("✅ Initial data inserted!");
  }

  Future<List<Map<String, dynamic>>> fetchCategories(Database db) async {
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> fetchItemsByCategory(Database db, String categoryName) async {
    final category = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [categoryName],
      limit: 1,
    );

    if (category.isEmpty) return [];

    final categoryId = category.first['id'];

    return await db.query(
      'shop_items',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  Future<List<String>> getAllTables(Database db) async {
    final result = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    
    // Veritabanındaki tüm tablolardan dönen sonuçları konsola yazdır
    print('Tablolar: $result');

    // Sadece tablonun adlarını döndürüyoruz.
    return result.map((row) => row['name'] as String).toList();
  }

  void printTables() async {
    final db = await _initDB('todo_app.db'); // Veritabanını başlat
    final tables = await getAllTables(db);   // Tüm tabloları al
    print('Veritabanındaki Tablolar:');
    for (var table in tables) {
      print(table);  // Tabloların adlarını yazdır
    }
  }

  // Genel daily task oluşturma (tüm kullanıcılar için)
  Future<void> generateDailyTasks() async {
    final db = await database;
    final today = DateTime.now();
    final dayOfWeek = today.weekday - 1; // 0=Pazartesi, 6=Pazar
    final todayString = today.toIso8601String().split('T')[0];
    
    print('🎯 Daily task oluşturma başlatıldı - Gün: $dayOfWeek, Tarih: $todayString');
    
    // Tüm aktif daily template'leri al
    final dailyTemplates = await db.query(
      'daily_templates',
      where: 'is_active = 1',
    );
    
    print('📋 ${dailyTemplates.length} aktif daily template bulundu');
    
    for (var template in dailyTemplates) {
      String selectedDays = template['selected_days'] as String;
      List<String> days = selectedDays.split(',');
      
      // Bugün bu daily çalışacak mı?
      if (dayOfWeek < days.length && days[dayOfWeek] == '1') {
        // Bugün için bu daily zaten oluşturulmuş mu?
        final existingTask = await db.query(
          'tasks',
          where: 'daily_template_id = ? AND DATE(created_at) = ?',
          whereArgs: [template['id'], todayString],
        );
        
        if (existingTask.isEmpty) {
          // Daily task'ı oluştur
          await db.insert('tasks', {
            'user_id': template['user_id'],
            'title': template['title'],
            'description': template['description'],
            'type': 'daily',
            'is_active': '1',
            'coin_reward': template['coin_reward'],
            'daily_template_id': template['id'],
          });
          
          print('✅ Daily task oluşturuldu: ${template['title']} (User: ${template['user_id']})');
        } else {
          print('⏭️ Daily task zaten var: ${template['title']}');
        }
      }
    }
  }

  // Belirli bir kullanıcı için daily task oluşturma
  Future<void> generateDailyTasksForUser(int userId) async {
    final db = await database;
    final today = DateTime.now();
    final dayOfWeek = today.weekday - 1; // 0=Pazartesi, 6=Pazar
    final todayString = today.toIso8601String().split('T')[0]; // 2025-06-09
    
    print('🎯 Kullanıcı $userId için daily task kontrolü başlatıldı - Gün: $dayOfWeek');
    
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
          // Bugün için bu daily henüz oluşturulmamış
          
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
          
          print('✅ Daily task oluşturuldu: ${template['title']}');
        } else {
          print('⏭️ Daily task zaten var: ${template['title']}');
        }
      } else {
        print('📅 Bugün çalışmayan daily: ${template['title']}');
      }
    }
  }

  // Daily template silindiğinde ilgili task'ları da sil
  Future<void> deleteDailyTemplate(int templateId) async {
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
      
      print('✅ Daily template ve ilgili tamamlanmamış task\'lar silindi: $templateId');
    } catch (e) {
      print('❌ Daily template silme hatası: $e');
      throw e;
    }
  }

  // YENİ: Daily edit edilince bugünkü task'ı deaktif et
  Future<void> deactivateTodayTaskForDaily(int dailyTemplateId, DateTime today) async {
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
        print('✅ Bugünkü tamamlanmamış task deaktif edildi: $dailyTemplateId');
      } else {
        print('ℹ️ Deaktif edilecek task bulunamadı (zaten tamamlanmış olabilir)');
      }
    } catch (e) {
      print('❌ Task deaktif etme hatası: $e');
      throw e;
    }
  }

  Future<void> exportDatabaseToJson() async {
    try {
      final db = await database;
      
      final users = await db.query('users');
      final tasks = await db.query('tasks');
      final dailyTemplates = await db.query('daily_templates');
      final taskCompletion = await db.query('task_completion');
      final categories = await db.query('categories');
      final shopItems = await db.query('shop_items');
      final userItems = await db.query('user_items');
      final streaks = await db.query('streaks');
      final userSelectedItems = await db.query('user_selected_items');
      final plans = await db.query('plans'); // 📅 Plans tablosu eklendi
      
      final databaseSnapshot = {
        'export_time': DateTime.now().toString(),
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
          'plans': plans, // 📅 Plans tablosu eklendi
        },
        'summary': {
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
          'total_plans': plans.length, // 📅 Plans sayısı eklendi
        }
      };
      
      final jsonString = JsonEncoder.withIndent('  ').convert(databaseSnapshot);
      
      // 🎯 1. Console'a yazdır
      print('📄 ===== DATABASE JSON START =====');
      print(jsonString);
      print('📄 ===== DATABASE JSON END =====');
      
      // 🎯 2. Clipboard'a kopyala
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      // 🎯 3. Dosyaya kaydet
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/database_snapshot.json');
      await file.writeAsString(jsonString);
      
      print('✅ JSON hazır: Console\'da + Clipboard\'ta + Dosyada');
      print('📋 Ctrl+V ile VS Code\'a yapıştırabilirsin!');
      
    } catch (e) {
      print('❌ JSON export hatası: $e');
      rethrow;
    }
  }

  // Yeni kullanıcıya tüm body'leri hediye et
  Future<void> giveAllBodiesToNewUser(int userId) async {
    final db = await instance.database;
    
    try {    
      // Body kategorisinin ID'sini al
      final bodyCategory = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: ['body'],
        limit: 1,
      );
      
      if (bodyCategory.isEmpty) {
        print("❌ Body kategorisi bulunamadı!");
        return;
      }
      
      final bodyCategoryId = bodyCategory.first['id'] as int;
      
      // Body kategorisindeki tüm item'ları al
      final bodyItems = await db.query(
        'shop_items',
        where: 'category_id = ?',
        whereArgs: [bodyCategoryId],
      );
      
      print("🎯 ${bodyItems.length} body item'ı bulundu");
      
      // Her body item'ını kullanıcıya ver
      for (var item in bodyItems) {
        await db.insert('user_items', {
          'user_id': userId,
          'item_id': item['id'],
          'purchased_at': DateTime.now().toIso8601String(),
        });
        
        print("✅ Body hediye edildi: ${item['name']} (ID: ${item['id']})");
      }
      
      // 🆕 İlk body'yi otomatik seç (body1)
      final firstBody = bodyItems.where((item) => item['name'] == 'body1').firstOrNull;
      if (firstBody != null) {
        await db.insert('user_selected_items', {
          'user_id': userId,
          'item_id': firstBody['id'],
        });
        print("🎯 İlk body otomatik seçildi: body1");
      }
      
      print("🎉 Kullanıcı $userId için tüm body'ler başarıyla hediye edildi!");
      
    } catch (e) {
      print("❌ Body hediye etme hatası: $e");
      throw e;
    }
  }



}