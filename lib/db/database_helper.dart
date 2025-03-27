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
          user_id INTEGER,
          title TEXT NOT NULL,
          description TEXT,
          type TEXT CHECK (type IN ('one_time', 'daily')),
          frequency INTEGER,
          coin_reward INTEGER DEFAULT 0,
          FOREIGN KEY (user_id) REFERENCES users(id)
      );
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

    // Eğer yoksa yeni kullanıcıyı ekle
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 1;  // Kayıt başarılı
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

  // Insert Shop Items
    await db.insert('shop_items', {'name': 'body1', 'category_id': 1, 'price': 5});
    await db.insert('shop_items', {'name': 'body2', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body3', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body4', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body5', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body6', 'category_id': 1, 'price': 10});
    await db.insert('shop_items', {'name': 'body7', 'category_id': 1, 'price': 10});

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
    tables.forEach((table) {
      print(table);  // Tabloların adlarını yazdır
    });
  }



}
