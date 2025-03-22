import 'package:sayfa_yonlendirme/models/user.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';


class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  static final _databaseName = "todo.db";

  DatabaseHelper._init();

Future<void> resetUsersTable() async {
  final db = await instance.database;

  // Mevcut users tablosunu sil
  await db.execute('DROP TABLE IF EXISTS users;');
  print('users tablosu silindi.');

  // Yeni users tablosunu oluştur
  await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      email TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      coins INTEGER DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_login TIMESTAMP  -- Yeni kolon ekledik
    );
  ''');
  print('Yeni users tablosu oluşturuldu.');
}




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
      id SERIAL PRIMARY KEY,
      username VARCHAR(50) UNIQUE NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      coins INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT NOW()
    );

    CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        type TEXT CHECK (type IN ('one_time', 'daily')),
        frequency INTEGER, -- Daily görevler için belirli bir sıklık (örn: her 1 gün, 3 gün vb.)
        coin_reward INTEGER DEFAULT 0
        FOREIGN KEY (user_id) REFERENCES users(id)
    );

    CREATE TABLE task_completion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER,
        completed_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
    );

    CREATE TABLE shop_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price INTEGER NOT NULL
    );

    CREATE TABLE user_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        item_id INTEGER,
        purchased_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id),
        FOREIGN KEY (item_id) REFERENCES shop_items(id)
    );

    CREATE TABLE streaks (
        id SERIAL PRIMARY KEY,
        user_id INTEGER,
        user_id INT REFERENCES users(id)
        date DATE NOT NULL,
        completed_tasks INT DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    );
    ''');
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




}
