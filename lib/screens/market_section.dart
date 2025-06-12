import 'package:flutter/material.dart';
import 'package:sayfa_yonlendirme/db/database_helper.dart';

class MarketSection extends StatefulWidget {
  final int userId; 
  final void Function(String category, String imagePath)? onItemSelected;

  const MarketSection({Key? key, required this.userId, this.onItemSelected}) : super(key: key);

  @override
  _MarketSectionState createState() => _MarketSectionState();
}

class _MarketSectionState extends State<MarketSection> with TickerProviderStateMixin {
  Map<String, String> selectedItems = {};
  Set<int> ownedItemIds = {}; // 🆕 Sahip olunan item ID'leri
  int userCoins = 0; // 🆕 Kullanıcı coin bilgisi
  late int userId;
  late AnimationController _categoryController;

  @override
  void initState() {
    super.initState();
    userId = widget.userId;
    _loadUserData(); // 🆕 Tüm kullanıcı verilerini yükle
    
    _categoryController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  List<Map<String, String>> categories = [
    {'name': 'body', 'icon': 'assets/category_icons/body.png'},
    {'name': 'eyes', 'icon': 'assets/category_icons/eyes.png'},
    {'name': 'mouth', 'icon': 'assets/category_icons/mouth.png'},
    {'name': 'hair', 'icon': 'assets/category_icons/hair.png'},
    {'name': 'top', 'icon': 'assets/category_icons/top.png'},
    {'name': 'bottom', 'icon': 'assets/category_icons/bottom.png'},
    {'name': 'shoes', 'icon': 'assets/category_icons/shoes.png'},
    {'name': 'accs', 'icon': 'assets/category_icons/accs.png'},
    {'name': 'hat', 'icon': 'assets/category_icons/hat.png'},
  ];

  Map<String, int> categoryIds = {
    'body': 1, 'eyes': 2, 'mouth': 3, 'hair': 4, 'top': 5,
    'bottom': 6, 'shoes': 7, 'accs': 8, 'hat': 9,
  };

  String selectedCategory = 'body';

  // 🆕 Tüm kullanıcı verilerini yükle
  Future<void> _loadUserData() async {
    await _loadUserSelectedItems();
    await _loadUserOwnedItems();
    await _loadUserCoins();
  }

  // 🆕 Kullanıcının sahip olduğu itemleri yükle
  Future<void> _loadUserOwnedItems() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'user_items',
      columns: ['item_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    setState(() {
      ownedItemIds = result.map((row) => row['item_id'] as int).toSet();
    });
    
    print('🛒 Sahip olunan itemler: $ownedItemIds');
  }

  // 🆕 Kullanıcının coin bilgisini yükle
  Future<void> _loadUserCoins() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query(
      'users',
      columns: ['coins'],
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      setState(() {
        userCoins = result.first['coins'] as int? ?? 0;
      });
    }
  }

  Future<void> _loadUserSelectedItems() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery('''
      SELECT s.name, s.category_id, c.name as category_name
      FROM user_selected_items u
      JOIN shop_items s ON u.item_id = s.id
      JOIN categories c ON s.category_id = c.id
      WHERE u.user_id = ?
    ''', [userId]);

    setState(() {
      selectedItems.clear();
      for (var row in result) {
        final category = row['category_name'] as String;
        final itemName = row['name'] as String;
        selectedItems[category] = 'assets/items/$category/$itemName.png';
      }
    });
  }

  Future<List<Map<String, dynamic>>> getItemsForSelectedCategory() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'shop_items',
      where: 'category_id = ?',
      whereArgs: [categoryIds[selectedCategory]],
    );
  }

  // 🆕 Item satın alma popup'ı
  void _showPurchaseDialog(Map<String, dynamic> item) {
    final itemName = item['name'] as String;
    final itemPrice = item['price'] as int;
    final itemId = item['id'] as int;
    final bool canAfford = userCoins >= itemPrice; // 🆕 Satın alabilir mi kontrolü

    showDialog(
      context: context,
      barrierDismissible: true, // 🆕 Her durumda dışarı tıklayarak kapanabilir
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: canAfford 
                        ? [Color(0xFF8B5CF6), Color(0xFF7C3AED)]
                        : [Color(0xFFEF4444), Color(0xFFDC2626)], // 🆕 Yetersizse kırmızı
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  canAfford ? Icons.shopping_cart : Icons.money_off, // 🆕 İkon değişimi
                  color: Colors.white, 
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                canAfford ? 'Satın Al' : 'Yetersiz Coin', // 🆕 Başlık değişimi
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item görseli
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFF404040),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/items/$selectedCategory/$itemName.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '$itemName',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$itemPrice',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text('🪙', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 12),
              // Coin durumu
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: canAfford 
                      ? Color(0xFF10B981).withOpacity(0.2)
                      : Color(0xFFEF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: canAfford 
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                  ),
                ),
                child: Text(
                  canAfford 
                      ? 'Yeterli coin var! 💰'
                      : 'Yetersiz coin! 😔',
                  style: TextStyle(
                    color: canAfford 
                        ? Color(0xFF10B981)
                        : Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // 🆕 Actions - Sadece coin yeterliyse tek buton
          actions: canAfford ? [
            // 🆕 Sadece Satın Al butonu - İptal butonu kaldırıldı
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _purchaseItem(itemId, itemPrice);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Satın Al 🛒',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ] : null, // 🆕 Coin yetersizse hiç buton gösterme
        );
      },
    );
  }



  // 🆕 Item satın alma işlemi
  Future<void> _purchaseItem(int itemId, int itemPrice) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // 1. Kullanıcının coin'ini düşür
        await txn.update(
          'users',
          {'coins': userCoins - itemPrice},
          where: 'id = ?',
          whereArgs: [userId],
        );
        
        // 2. Item'i kullanıcının envanterine ekle
        await txn.insert('user_items', {
          'user_id': userId,
          'item_id': itemId,
        });
      });
      
      // 3. UI'ı güncelle
      await _loadUserData();
      
      // 4. Başarı mesajı
      _showSnackBar('✅ Item başarıyla satın alındı!', Colors.green);
      
      print('✅ Item satın alındı: $itemId, Kalan coin: ${userCoins - itemPrice}');
      
    } catch (e) {
      _showSnackBar('❌ Satın alma hatası: $e', Colors.red);
      print('❌ Satın alma hatası: $e');
    }
  }

  // 🆕 SnackBar gösterici
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF404040),
            Color(0xFF2D2D2D),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STORE başlığı
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'STORE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Spacer(),
                // 🆕 Coin göstergesi
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$userCoins',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('🪙', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Kategori Butonları
          Container(
            height: 70,
            margin: EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat['name'] == selectedCategory;

                return Container(
                  margin: EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat['name']!;
                      });
                      _categoryController.forward().then((_) {
                        _categoryController.reverse();
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? LinearGradient(
                                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : Color(0xFF6B6B6B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Color(0xFF8B5CF6).withOpacity(0.4),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ] : null,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            cat['icon']!,
                            fit: BoxFit.contain,
                            color: Colors.white,
                            height: 28,
                          ),
                          SizedBox(height: 2),
                          Text(
                            cat['name']!.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 🎯 Grid Items - YENİ LOCK SİSTEMİ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getItemsForSelectedCategory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF8B5CF6),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Yükleniyor...",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.white30,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Bu kategoriye ait item bulunamadı.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data!;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: BouncingScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final itemId = item['id'] as int;
                      final itemPrice = item['price'] as int;
                      String imagePath = 'assets/items/$selectedCategory/${item['name']}.png';
                      bool isItemSelected = selectedItems[selectedCategory] == imagePath;
                      bool isOwned = ownedItemIds.contains(itemId); // 🆕 Sahiplik kontrolü

                      return GestureDetector(
                        onTap: () async {
                          if (!isOwned) {
                            // 🆕 Kilitli item - satın alma popup'ı göster
                            _showPurchaseDialog(item);
                            return;
                          }

                          // Sahip olunan item - normal seçim işlemi
                          final db = await DatabaseHelper.instance.database;

                          await db.delete(
                            'user_selected_items',
                            where: 'user_id = ? AND item_id IN (SELECT id FROM shop_items WHERE category_id = ?)',
                            whereArgs: [userId, categoryIds[selectedCategory]],
                          );

                          await db.insert('user_selected_items', {
                            'user_id': userId,
                            'item_id': item['id'],
                          });

                          if (widget.onItemSelected != null) {
                            widget.onItemSelected!(selectedCategory, imagePath);
                          }

                          setState(() {
                            selectedItems[selectedCategory] = imagePath;
                          });
                        },
                        child: Stack(
                          children: [
                            // Ana container
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: isItemSelected 
                                    ? LinearGradient(
                                        colors: [
                                          Color(0xFF8B5CF6).withOpacity(0.3),
                                          Color(0xFF7C3AED).withOpacity(0.3),
                                        ],
                                      )
                                    : null,
                                color: isItemSelected ? null : Color(0xFF6B6B6B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isItemSelected
                                      ? Color(0xFF8B5CF6)
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isItemSelected ? [
                                  BoxShadow(
                                    color: Color(0xFF8B5CF6).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ] : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                            ),
                            
                            // 🆕 Sol üst köşe - Kilit ikonu (sadece kilitli itemlerde)
                            if (!isOwned)
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                            
                            // 🆕 Sağ üst köşe - Fiyat etiketi (sadece kilitli itemlerde)
                            if (!isOwned)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$itemPrice',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 2),
                                      Text('🪙', style: TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
